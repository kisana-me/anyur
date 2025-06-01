class CreateActivityLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :activity_logs do |t|
      t.string :account_id, null: false, limit: 14
      t.string :action_name, null: false, default: ""
      t.string :previous_value, null: false, default: ""
      t.string :new_value, null: false, default: ""
      t.datetime :changed_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }
      t.string :change_reason, null: false, default: ""
      t.json :meta, null: false, default: {}

      t.timestamps
    end
    add_foreign_key :activity_logs, :accounts, column: :account_id
    add_index :activity_logs, :account_id
  end
end
