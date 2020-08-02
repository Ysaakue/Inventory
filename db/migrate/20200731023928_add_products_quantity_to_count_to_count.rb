class AddProductsQuantityToCountToCount < ActiveRecord::Migration[6.0]
  def change
    add_column :counts, :products_quantity_to_count, :integer
  end
end
