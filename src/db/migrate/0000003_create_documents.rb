class CreateDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :documents do |t|
      t.string :aid, null: false, limit: 14
      t.string :name, null: false, default: ""
      t.string :name_id, null: false, default: ""
      t.string :summary, null: false, default: ""
      t.text :content, null: false, default: ""
      t.text :content_cache, null: false, default: ""
      t.datetime :published_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.datetime :edited_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.integer :visibility_status, null: false, limit: 1, default: 0
      t.json :meta, null: false, default: {}
      t.integer :status, null: false, limit: 1, default: 0
      t.boolean :deleted, null: false, default: false

      t.timestamps
    end
    add_index :documents, :aid, unique: true
    add_index :documents, :name_id, unique: true
  end
end
