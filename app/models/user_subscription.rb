class UserSubscription < ApplicationRecord
  belongs_to :user
  
  # Subscription types
  TYPES = {
    standard: 'standard',
    enterprise: 'enterprise'
  }.freeze
  
  # Prices in cents
  PRICES = {
    standard: 300,  # $3 per 100 calls = $0.03 per call
    enterprise: 500  # $5 per 100 calls = $0.05 per call (with additional benefits)
  }.freeze
  
  validates :subscription_type, presence: true, inclusion: { in: TYPES.values }
  validates :stripe_subscription_id, presence: true, uniqueness: true, allow_nil: true
  validates :starts_at, presence: true
  
  # Scopes for filtering subscriptions
  scope :active, -> { where('starts_at <= ? AND (ends_at IS NULL OR ends_at > ?)', Time.current, Time.current) }
  scope :expired, -> { where('ends_at IS NOT NULL AND ends_at <= ?', Time.current) }
  scope :standard, -> { where(subscription_type: TYPES[:standard]) }
  scope :enterprise, -> { where(subscription_type: TYPES[:enterprise]) }
  
  # Retrieve the Stripe subscription
  def stripe_subscription
    return nil unless stripe_subscription_id.present?
    
    @stripe_subscription ||= Stripe::Subscription.retrieve(stripe_subscription_id)
  rescue Stripe::InvalidRequestError
    nil
  end
  
  # Check if subscription is active
  def active?
    return false unless starts_at
    
    starts_at <= Time.current && (ends_at.nil? || ends_at > Time.current)
  end
  
  # Cancel the subscription
  def cancel!
    return false unless stripe_subscription_id.present?
    
    begin
      # Cancel at Stripe level if needed
      Stripe::Subscription.update(
        stripe_subscription_id,
        { cancel_at_period_end: true }
      )
      
      # Update local record
      update(ends_at: Time.current)
      true
    rescue => e
      Rails.logger.error "Subscription cancellation error: #{e.message}"
      false
    end
  end
  
  # Get tools included with this subscription
  def tool_inclusions
    case subscription_type
    when TYPES[:enterprise]
      # Enterprise includes all tools
      PaidTool.descendants.map(&:name)
    when TYPES[:standard]
      # Standard might include specific tools or have a limit
      # For now, let's assume it includes all tools with a usage limit
      PaidTool.descendants.map(&:name)
    else
      []
    end
  end
  
  # Is this subscription of a specific type?
  def standard?
    subscription_type == TYPES[:standard]
  end
  
  def enterprise?
    subscription_type == TYPES[:enterprise]
  end
end
