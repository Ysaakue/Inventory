class RemoveRolePermissionsFromUser < ActiveRecord::Migration[6.0]
  def change
    remove_column :users, :role
    remove_column :users, :permissions
  end
end
