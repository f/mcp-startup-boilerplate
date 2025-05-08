class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :access_grants,
           class_name: 'Doorkeeper::AccessGrant',
           foreign_key: :resource_owner_id,
           dependent: :delete_all # or :destroy if you need callbacks

  has_many :access_tokens,
           class_name: 'Doorkeeper::AccessToken',
           foreign_key: :resource_owner_id,
           dependent: :delete_all # or :destroy if you need callbacks
           
  has_many :subscriptions, class_name: 'UserSubscription', dependent: :destroy
  has_many :tool_usages, class_name: 'UserToolUsage', dependent: :destroy
  
  # Stripe customer management
  def stripe_customer
    return nil unless stripe_customer_id.present?
    
    @stripe_customer ||= Stripe::Customer.retrieve(stripe_customer_id)
  rescue Stripe::InvalidRequestError
    nil
  end
  
  def ensure_stripe_customer!
    return stripe_customer if stripe_customer.present?
    
    # Create a new customer
    customer = Stripe::Customer.create(
      email: email,
      name: name || email
    )
    
    # Update the user record
    update(stripe_customer_id: customer.id)
    
    customer
  end
  
  # Subscription management
  def active_subscription?
    subscriptions.active.exists?
  end
  
  def subscription_covers_tool?(tool_name)
    return false unless active_subscription?
    
    # Enterprise subscription covers all tools
    return true if subscriptions.active.enterprise.exists?
    
    # Check if standard subscription includes this tool
    subscriptions.active.standard.any? do |sub|
      sub.tool_inclusions.include?(tool_name)
    end
  end
  
  # Usage statistics
  def tool_usage_count(tool_name = nil)
    scope = tool_usages
    scope = scope.for_tool(tool_name) if tool_name.present?
    scope.count
  end
  
  def total_spent_cents
    tool_usages.sum(:price_cents)
  end
end
