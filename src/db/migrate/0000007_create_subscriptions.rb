class CreateSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :subscriptions, id: false do |t|
      t.string :id, null: false, limit: 14, primary_key: true
      t.string :account_id, null: false
      t.string :stripe_subscription_id, null: false, default: ""
      t.string :stripe_plan_id, null: false, default: ""
      t.datetime :current_period_start
      t.datetime :current_period_end
      t.boolean :cancel_at_period_end, default: false
      t.datetime :canceled_at
      t.datetime :trial_start_at
      t.datetime :trial_end_at
      t.json :cache, null: false, default: {}
      t.json :settings, null: false, default: {}
      t.json :meta, null: false, default: {}
      t.integer :status, null: false, limit: 1, default: 0
      t.boolean :deleted, null: false, default: false

      t.timestamps
    end
    add_foreign_key :subscriptions, :accounts, column: :account_id
    add_index :subscriptions, :account_id
    add_index :subscriptions, :stripe_subscription_id, unique: true
  end
end
