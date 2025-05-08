# frozen_string_literal: true

class WebhooksController < ApplicationController
  # Skip authentication and CSRF protection for webhook endpoints
  before_action :verify_authenticity_token, only: []
  before_action :authenticate_user!, only: []
  
  # Handle Stripe webhook events
  def stripe
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    endpoint_secret = Rails.configuration.stripe[:signing_secret]
    
    begin
      # Verify the event using the Stripe signing secret
      event = Stripe::Webhook.construct_event(
        payload, sig_header, endpoint_secret
      )
    rescue JSON::ParserError => e
      # Invalid payload
      return head :bad_request
    rescue Stripe::SignatureVerificationError => e
      # Invalid signature
      return head :bad_request
    end
    
    # Handle the event based on its type
    case event.type
    when 'customer.subscription.created', 'customer.subscription.updated'
      handle_subscription_updated(event.data.object)
    when 'customer.subscription.deleted'
      handle_subscription_canceled(event.data.object)
    when 'invoice.payment_succeeded'
      handle_payment_succeeded(event.data.object)
    when 'invoice.payment_failed'
      handle_payment_failed(event.data.object)
    else
      # Unhandled event type
      Rails.logger.info "Unhandled Stripe event: #{event.type}"
    end
    
    head :ok
  end
  
  private
  
  def handle_subscription_updated(subscription)
    # Find the user by Stripe customer ID
    pp "subscription: #{subscription}"
    user = User.find_by(stripe_customer_id: subscription.customer)
    return unless user
    
    # Find or create subscription record
    user_subscription = user.subscriptions.find_or_initialize_by(
      stripe_subscription_id: subscription.id
    )
    
    # Determine subscription type from Stripe product/price
    subscription_type = get_subscription_type_from_stripe(subscription)
    
    # Update record with latest data
    user_subscription.update(
      subscription_type: subscription_type,
      starts_at: Time.at(subscription.current_period_start),
      ends_at: subscription.cancel_at ? Time.at(subscription.cancel_at) : nil
    )
    
    Rails.logger.info "Updated subscription #{subscription.id} for user #{user.id}"
  end
  
  def handle_subscription_canceled(subscription)
    # Find the subscription in our database
    user_subscription = UserSubscription.find_by(stripe_subscription_id: subscription.id)
    return unless user_subscription
    
    # Mark as canceled
    user_subscription.update(ends_at: Time.at(subscription.canceled_at || Time.now.to_i))
    
    Rails.logger.info "Canceled subscription #{subscription.id}"
  end
  
  def handle_payment_succeeded(invoice)
    # Find the user by Stripe customer ID
    user = User.find_by(stripe_customer_id: invoice.customer)
    return unless user
    
    # Log successful payment
    Rails.logger.info "Payment succeeded for invoice #{invoice.id}, user #{user.id}"
    
    # # If this is a subscription invoice, update subscription status
    # if invoice.subscription
    #   subscription = Stripe::Subscription.retrieve(invoice.subscription)
    #   handle_subscription_updated(subscription)
    # end
  end
  
  def handle_payment_failed(invoice)
    # Find the user by Stripe customer ID
    user = User.find_by(stripe_customer_id: invoice.customer)
    return unless user
    
    # Log failed payment
    Rails.logger.info "Payment failed for invoice #{invoice.id}, user #{user.id}"
    
    # You might want to notify the user by email here
  end
  
  def get_subscription_type_from_stripe(subscription)
    # The implementation depends on how you set up your Stripe products and prices
    # Here's a simple example assuming you have products with specific IDs
    
    # Get the first item from the subscription
    item = subscription.items.data.first
    return UserSubscription::TYPES[:standard] unless item
    
    price = item.price
    product = Stripe::Product.retrieve(price.product)
    
    case product.metadata[:subscription_type]
    when 'enterprise'
      UserSubscription::TYPES[:enterprise]
    else
      UserSubscription::TYPES[:standard]
    end
  rescue
    # Default to standard if we can't determine the type
    UserSubscription::TYPES[:standard]
  end
end 