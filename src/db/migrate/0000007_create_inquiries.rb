class CreateInquiries < ActiveRecord::Migration[8.0]
  def change
    create_table :inquiries do |t|
      t.string :aid, null: false, limit: 14
      t.references :account, null: true, foreign_key: true
      t.references :service, null: true, foreign_key: true
      t.string :subject, null: false
      t.text :content, null: false
      t.string :name, null: false
      t.string :email, null: false, default: ""
      t.text :memo, null: false, default: ""
      t.json :meta, null: false, default: {}
      t.integer :status, null: false, limit: 1, default: 0

      t.timestamps
    end
    add_index :inquiries, :aid, unique: true
  end
end
