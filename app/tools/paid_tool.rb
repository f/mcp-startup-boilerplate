# frozen_string_literal: true

class PaidTool < ApplicationTool
  class PaymentError < StandardError; end
  
  DEFAULT_PRICE_CENTS = 5 # $0.05 per call
  
  # Override this in child classes if needed
  def price_cents
    DEFAULT_PRICE_CENTS
  end
  
  # Execute the tool action after charging the user
  def execute
    return unless charge_user
    
    super
  end
  
  private
  
  def charge_user
    return true if Rails.env.development? && ENV['SKIP_PAYMENT'] == 'true'
    
    user = current_user
    return false unless user
    
    begin
      # Check if user has a subscription that covers this
      if user_has_subscription?
        record_tool_usage
        return true
      end
      
      # Otherwise charge per usage
      charge = Stripe::Charge.create({
        amount: price_cents,
        currency: 'usd',
        customer: user.stripe_customer_id,
        description: "Usage of #{self.class.name}"
      })
      
      record_tool_usage(charge_id: charge.id)
      true
    rescue Stripe::CardError => e
      # Card was declined
      raise PaymentError, "Payment failed: #{e.message}"
    rescue => e
      # Something else happened
      raise PaymentError, "An error occurred processing the payment"
    end
  end
  
  def user_has_subscription?
    user = current_user
    return false unless user
    
    user.active_subscription? && user.subscription_covers_tool?(self.class.name)
  end
  
  def record_tool_usage(charge_id: nil)
    UserToolUsage.create!(
      user: current_user,
      tool_name: self.class.name,
      price_cents: price_cents,
      charge_id: charge_id
    )
  end
end 