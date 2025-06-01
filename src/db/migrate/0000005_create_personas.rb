class CreatePersonas < ActiveRecord::Migration[8.0]
  def change
    create_table :personas, id: false do |t|
      t.string :id, null: false, limit: 14, primary_key: true
      t.string :account_id, null: false, limit: 14
      t.string :service_id, null: false, limit: 14
      t.string :name, null: false, default: ""
      t.string :authorization_code_lookup, null: false, default: ""
      t.string :authorization_code_digest, null: false, default: ""
      t.datetime :authorization_code_expires_at
      t.datetime :authorization_code_generated_at
      t.string :access_token_lookup, null: false, default: ""
      t.string :access_token_digest, null: false, default: ""
      t.datetime :access_token_expires_at
      t.datetime :access_token_generated_at
      t.string :refresh_token_lookup, null: false, default: ""
      t.string :refresh_token_digest, null: false, default: ""
      t.datetime :refresh_token_expires_at
      t.datetime :refresh_token_generated_at
      t.json :scopes, null: false, default: []
      t.json :cache, null: false, default: {}
      t.json :settings, null: false, default: {}
      t.json :meta, null: false, default: {}
      t.integer :status, null: false, limit: 1, default: 0
      t.boolean :deleted, null: false, default: false

      t.timestamps
    end
    add_foreign_key :personas, :accounts, column: :account_id
    add_index :personas, :account_id
    add_foreign_key :personas, :services, column: :service_id
    add_index :personas, :service_id
    add_index :personas, :authorization_code_lookup, unique: true
    add_index :personas, :access_token_lookup, unique: true
    add_index :personas, :refresh_token_lookup, unique: true
  end
end
