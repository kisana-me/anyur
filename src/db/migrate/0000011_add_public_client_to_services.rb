class AddPublicClientToServices < ActiveRecord::Migration[8.0]
  def up
    add_column :services, :public_client, :boolean, null: false, default: false
  end

  def down
    remove_column :services, :public_client
  end
end