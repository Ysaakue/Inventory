class AddIgnoreAndJustificationToCountProduct < ActiveRecord::Migration[6.0]
  def change
    add_column :count_products, :ignore, :boolean
    add_column :count_products, :justification, :string
  end
end
