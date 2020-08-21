class ChangeDefaults < ActiveRecord::Migration[6.0]
  def change
    change_column_default :counts, :accuracy, 0
    change_column_default :count_products, :percentage_result, 0
    change_column_default :count_products, :final_total_value, 0
    change_column_default :count_products, :percentage_result_value, 0
end
end
