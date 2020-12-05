class AddRoleToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :role_id, :integer
  end
end
