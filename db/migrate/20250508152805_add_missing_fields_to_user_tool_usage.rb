class AddMissingFieldsToUserToolUsage < ActiveRecord::Migration[8.0]
  def change
    # Rename column to match our model
    rename_column :user_tool_usages, :cost_in_cents, :price_cents
    
    # Add missing fields
    add_column :user_tool_usages, :charge_id, :string
    add_column :user_tool_usages, :refunded_at, :datetime
    add_column :user_tool_usages, :refund_id, :string
    
    # Remove fields we don't need
    remove_column :user_tool_usages, :processed, :boolean
    remove_column :user_tool_usages, :timestamp, :datetime
    remove_column :user_tool_usages, :stripe_charge_id, :string
    
    # Add indexes
    add_index :user_tool_usages, :tool_name
    add_index :user_tool_usages, :charge_id
  end
end
