class CreateProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :profiles, id: false do |t|
      t.string :id, null: false, limit: 24, primary_key: true
      t.string :account_id, null: false
      t.string :service_id, null: false
      t.string :name, null: false, default: ''
      t.json :settings, null: false, default: {}
      t.json :meta, null: false, default: {}
      t.integer :status, null: false, limit: 1, default: 0
      t.boolean :deleted, null: false, default: false

      t.timestamps
    end
    add_foreign_key :profiles, :accounts, column: :account_id
    add_index :profiles, :account_id
    add_foreign_key :profiles, :services, column: :service_id
    add_index :profiles, :service_id
  end
end
