class ChangeUsersColumns < ActiveRecord::Migration[6.0]
  def change
    remove_column :users, :nickname
    remove_column :users, :image
    remove_column :users, :admin
    remove_column :users, :client_id
    add_column :users, :role, :integer, null: false, default: 0
    add_column :users, :permissions, :json
  end
end
