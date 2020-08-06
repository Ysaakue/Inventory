class AddNewToProduct < ActiveRecord::Migration[6.0]
  def change
    add_column :products, :new, :boolean, default: true
  end
end
