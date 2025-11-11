class CreateServices < ActiveRecord::Migration[8.0]
  def change
    create_table :services do |t|
      t.string :aid, null: false, limit: 14
      t.string :name, null: false
      t.string :name_id, null: false
      t.string :overview, null: false, default: ""
      t.text :description, null: false, default: ""
      t.string :host, null: false
      t.string :client_secret_lookup, null: false
      t.string :client_secret_digest, null: false
      t.datetime :client_secret_expires_at, null: false
      t.datetime :client_secret_generated_at, null: false
      t.json :redirect_uris, null: false, default: []
      t.json :scopes, null: false, default: []
      t.json :meta, null: false, default: {}
      t.integer :status, null: false, limit: 1, default: 0

      t.timestamps
    end
    add_index :services, :aid, unique: true
    add_index :services, :name_id, unique: true
    add_index :services, :client_secret_lookup, unique: true
  end
end
