class AddInvalidProductsToImport < ActiveRecord::Migration[6.0]
  def change
    add_column :imports, :invalid_products, :json
  end
end
