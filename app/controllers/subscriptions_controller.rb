# frozen_string_literal: true

class SubscriptionsController < ApplicationController
  before_action :authenticate_user!
  
  # Display subscription management page
  def index
    @active_subscription = current_user.subscriptions.active.first
    @subscription_history = current_user.subscriptions.order(created_at: :desc)
    @tool_usage = current_user.tool_usages.latest.limit(10)
  end
  
  # Display the subscription checkout form
  def new
    @subscription_type = params[:type] || UserSubscription::TYPES[:standard]
    
    # Ensure user has a Stripe customer ID
    current_user.ensure_stripe_customer!
    
    # Set up checkout session for the subscription
    @stripe_publishable_key = Rails.configuration.stripe[:publishable_key]
  end
  
  # Create a Stripe checkout session for the subscription
  def create
    subscription_type = params[:subscription_type] || UserSubscription::TYPES[:standard]
    
    # Ensure user has a Stripe customer ID
    current_user.ensure_stripe_customer!
    
    # Create a checkout session
    price_id = get_price_id_for_subscription(subscription_type)
    
    session = Stripe::Checkout::Session.create({
      customer: current_user.stripe_customer_id,
      payment_method_types: ['card'],
      line_items: [{
        price: price_id,
        quantity: 1
      }],
      mode: 'subscription',
      success_url: subscription_success_url,
      cancel_url: subscription_cancel_url
    })
    
    # Redirect to Stripe Checkout with Turbo disabled
    # Use redirect_to with status: 303 to ensure proper redirect to external Stripe URL
    # The allow_other_host: true is required for external redirects in Rails 7+
    redirect_to session.url, allow_other_host: true, status: 303, data: { turbo: false }
  end
  
  # Cancel the current subscription
  def destroy
    subscription = current_user.subscriptions.active.find(params[:id])
    
    if subscription.cancel!
      redirect_to subscriptions_path, notice: 'Subscription has been canceled.'
    else
      redirect_to subscriptions_path, alert: 'Failed to cancel subscription. Please try again.'
    end
  end
  
  # Handle successful subscription checkout
  def success
    # The actual subscription update will be handled by the webhook
    redirect_to subscriptions_path, notice: 'Your subscription has been activated!'
  end
  
  # Handle canceled subscription checkout
  def cancel
    redirect_to subscriptions_path, alert: 'Subscription checkout was canceled.'
  end
  
  private
  
  # Get the appropriate Stripe Price ID based on subscription type
  def get_price_id_for_subscription(subscription_type)
    case subscription_type
    when UserSubscription::TYPES[:enterprise]
      ENV['STRIPE_ENTERPRISE_PRICE_ID'] || 'price_enterprise_example'
    else
      ENV['STRIPE_STANDARD_PRICE_ID'] || 'price_standard_example'
    end
  end
end 