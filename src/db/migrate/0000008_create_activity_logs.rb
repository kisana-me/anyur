class CreateActivityLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :activity_logs do |t|
      t.string :aid, null: false, limit: 14
      t.references :account, null: true, foreign_key: true
      t.references :loggable, polymorphic: true, null: true
      t.string :action_name, null: false, default: ""
      t.json :attribute_data, null: false, default: []
      t.datetime :changed_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.string :change_reason, null: false, default: ""
      t.string :user_agent, null: false, default: ""
      t.string :ip_address, null: false, default: ""
      t.json :meta, null: false, default: {}
      t.integer :status, null: false, limit: 1, default: 0
      t.boolean :deleted, null: false, default: false

      t.timestamps
    end
    add_index :activity_logs, :aid, unique: true
  end
end
