class AddAdminAndClientIdToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :admin, :boolean, default: false
    add_column :users, :client_id, :integer
  end
end
