class CreateUserToolUsages < ActiveRecord::Migration[8.0]
  def change
    create_table :user_tool_usages do |t|
      t.references :user, null: false, foreign_key: true
      t.string :tool_name
      t.integer :cost_in_cents
      t.datetime :timestamp
      t.boolean :processed
      t.string :stripe_charge_id

      t.timestamps
    end
  end
end
