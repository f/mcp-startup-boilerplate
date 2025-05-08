class UpdateUserSubscriptionFields < ActiveRecord::Migration[8.0]
  def change
    # Rename columns to match our model
    rename_column :user_subscriptions, :plan_type, :subscription_type
    rename_column :user_subscriptions, :current_period_start, :starts_at
    rename_column :user_subscriptions, :current_period_end, :ends_at
    
    # Remove unnecessary column - status is derived from starts_at and ends_at
    remove_column :user_subscriptions, :status, :string
    
    # Remove duplicate column - stripe_customer_id should only be on User model
    remove_column :user_subscriptions, :stripe_customer_id, :string
    
    # Add index for faster queries
    add_index :user_subscriptions, :subscription_type
    add_index :user_subscriptions, :stripe_subscription_id, unique: true
  end
end
