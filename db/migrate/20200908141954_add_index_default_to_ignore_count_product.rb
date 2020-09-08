class AddIndexDefaultToIgnoreCountProduct < ActiveRecord::Migration[6.0]
  def change
    change_column :count_products, :ignore, :boolean, default: false
  end
end
