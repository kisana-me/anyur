class CreateServices < ActiveRecord::Migration[8.0]
  def change
    create_table :services do |t|
      t.string :aid, null: false, limit: 14
      t.string :name, null: false, default: ""
      t.string :name_id, null: false, default: ""
      t.string :summary, null: false, default: ""
      t.text :description, null: false, default: ""
      t.text :description_cache, null: false, default: ""
      t.string :host, null: false, default: ""
      t.string :client_secret_lookup, null: false, default: ""
      t.string :client_secret_digest, null: false, default: ""
      t.datetime :client_secret_expires_at, default: -> { "CURRENT_TIMESTAMP" }
      t.datetime :client_secret_generated_at, default: -> { "CURRENT_TIMESTAMP" }
      t.json :redirect_uris, null: false, default: []
      t.json :scopes, null: false, default: []
      t.json :meta, null: false, default: {}
      t.integer :status, null: false, limit: 1, default: 0
      t.boolean :deleted, null: false, default: false

      t.timestamps
    end
    add_index :services, :aid, unique: true
    add_index :services, :name_id, unique: true
  end
end
