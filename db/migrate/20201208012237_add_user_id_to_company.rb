class AddUserIdToCompany < ActiveRecord::Migration[6.0]
  def change
    add_column :companies, :user_id, :integer
  end
end
