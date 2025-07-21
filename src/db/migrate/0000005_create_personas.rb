class CreatePersonas < ActiveRecord::Migration[8.0]
  def change
    create_table :personas do |t|
      t.string :aid, null: false, limit: 14
      t.references :account, null: false, foreign_key: true
      t.references :service, null: false, foreign_key: true
      t.string :name, null: false, default: ""
      t.string :authorization_code_lookup, null: false, default: ""
      t.string :authorization_code_digest, null: false, default: ""
      t.datetime :authorization_code_expires_at, default: -> { "CURRENT_TIMESTAMP" }
      t.datetime :authorization_code_generated_at, default: -> { "CURRENT_TIMESTAMP" }
      t.string :access_token_lookup, null: false, default: ""
      t.string :access_token_digest, null: false, default: ""
      t.datetime :access_token_expires_at, default: -> { "CURRENT_TIMESTAMP" }
      t.datetime :access_token_generated_at, default: -> { "CURRENT_TIMESTAMP" }
      t.string :refresh_token_lookup, null: false, default: ""
      t.string :refresh_token_digest, null: false, default: ""
      t.datetime :refresh_token_expires_at, default: -> { "CURRENT_TIMESTAMP" }
      t.datetime :refresh_token_generated_at, default: -> { "CURRENT_TIMESTAMP" }
      t.json :scopes, null: false, default: []
      t.json :meta, null: false, default: {}
      t.integer :status, null: false, limit: 1, default: 0
      t.boolean :deleted, null: false, default: false

      t.timestamps
    end
    add_index :personas, :aid, unique: true
    add_index :personas, :authorization_code_lookup, unique: true
    add_index :personas, :access_token_lookup, unique: true
    add_index :personas, :refresh_token_lookup, unique: true
  end
end
