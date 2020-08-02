class AddIndexDefaulToActiveProduct < ActiveRecord::Migration[6.0]
  def change
    change_column :products, :active, :boolean, default: true
  end
end
