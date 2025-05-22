class CreateInquiries < ActiveRecord::Migration[8.0]
  def change
    create_table :inquiries, id: false do |t|
      t.string :id, null: false, limit: 14, primary_key: true
      t.string :account_id, null: true
      t.string :service_id, null: true
      t.string :subject, null: false, default: ""
      t.string :summary, null: false, default: ""
      t.text :content, null: false, default: ""
      t.text :name, null: false, default: ""
      t.string :email, null: false, default: ""
      t.text :memo, null: false, default: ""
      t.json :cache, null: false, default: {}
      t.json :settings, null: false, default: {}
      t.json :meta, null: false, default: {}
      t.integer :status, null: false, limit: 1, default: 0
      t.boolean :deleted, null: false, default: false

      t.timestamps
    end
    add_foreign_key :inquiries, :accounts, column: :account_id
    add_index :inquiries, :account_id
    add_foreign_key :inquiries, :services, column: :service_id
    add_index :inquiries, :service_id
  end
end
