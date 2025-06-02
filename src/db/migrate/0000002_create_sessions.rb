class CreateSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :sessions, id: false do |t|
      t.string :id, null: false, limit: 14, primary_key: true
      t.string :account_id, null: false, limit: 14
      t.string :name, null: false, default: ""
      t.string :user_agent, null: false, default: ""
      t.string :ip_address, null: false, default: ""
      t.string :token_lookup, null: false, default: ""
      t.string :token_digest, null: false, default: ""
      t.datetime :token_expires_at
      t.datetime :token_generated_at
      t.json :meta, null: false, default: {}
      t.integer :status, null: false, limit: 1, default: 0
      t.boolean :deleted, null: false, default: false

      t.timestamps
    end
    add_foreign_key :sessions, :accounts, column: :account_id
    add_index :sessions, :account_id
  end
end
