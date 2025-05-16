class CreateServices < ActiveRecord::Migration[8.0]
  def change
    create_table :services, id: false do |t|
      t.string :id, null: false, limit: 24, primary_key: true
      t.string :name, null: false, default: ''
      t.text :description, null: false, default: ''
      t.string :host, null: false, default: ''
      t.string :callback, null: false, default: ''
      t.json :meta, null: false, default: {}
      t.integer :status, null: false, limit: 1, default: 0
      t.boolean :deleted, null: false, default: false

      t.timestamps
    end
  end
end
