class AddFieldsToCountProduct < ActiveRecord::Migration[6.0]
  def change
    add_column :count_products, :total_value, :float
    add_column :count_products, :percentage_result, :float
    add_column :count_products, :final_total_value, :float
    add_column :count_products, :percentage_result_value, :float
  end
end
