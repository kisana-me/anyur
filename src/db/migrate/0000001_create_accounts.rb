class CreateAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :accounts do |t|
      t.string :aid, null: false, limit: 14
      t.string :name, null: false
      t.string :name_id, null: false
      t.text :description, null: false, default: ""
      t.datetime :birthday, null: true
      t.string :email, null: true
      t.boolean :email_verified, null: false, default: false
      t.integer :visibility, limit: 1, null: false, default: 0
      t.string :password_digest, null: true
      t.string :stripe_customer_id, null: true
      t.json :meta, null: false, default: {}
      t.integer :status, null: false, limit: 1, default: 0

      t.timestamps
    end
    add_index :accounts, :aid, unique: true
    add_index :accounts, :name_id, unique: true
    add_index :accounts, :email, unique: true
    add_index :accounts, :stripe_customer_id, unique: true
  end
end
