class CreateAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :accounts, id: false do |t|
      t.string :id, null: false, limit: 14, primary_key: true
      t.string :name, null: false, default: ""
      t.string :name_id, null: false, default: ""
      t.string :email, null: false, default: ""
      t.boolean :email_verified, null: false, default: false
      t.string :roles, null: false, default: ""
      t.string :password_digest, null: false, default: ""
      t.json :cache, null: false, default: {}
      t.json :settings, null: false, default: {}
      t.json :meta, null: false, default: {}
      t.integer :status, null: false, limit: 1, default: 0
      t.boolean :deleted, null: false, default: false

      t.timestamps
    end
    add_index :accounts, :name_id, unique: true
  end
end
