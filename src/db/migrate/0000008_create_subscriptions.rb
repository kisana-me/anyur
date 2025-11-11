class CreateSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :subscriptions do |t|
      t.string :aid, null: false, limit: 14
      t.references :account, null: false, foreign_key: true
      t.string :stripe_subscription_id, null: false
      t.string :stripe_plan_id, null: false
      t.datetime :current_period_start, null: false
      t.datetime :current_period_end, null: false
      t.boolean :cancel_at_period_end, null: false, default: false
      t.datetime :canceled_at, null: true
      t.datetime :trial_start_at, null: true
      t.datetime :trial_end_at, null: true
      t.integer :subscription_status, null: false, limit: 1, default: 0
      t.json :meta, null: false, default: {}
      t.integer :status, null: false, limit: 1, default: 0

      t.timestamps
    end
    add_index :subscriptions, :aid, unique: true
    add_index :subscriptions, :stripe_subscription_id, unique: true
  end
end
