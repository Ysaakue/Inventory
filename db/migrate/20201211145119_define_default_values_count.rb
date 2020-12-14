class DefineDefaultValuesCount < ActiveRecord::Migration[6.0]
  def change
    change_column :counts, :initial_value, :float, default: 0
    change_column :counts, :initial_stock, :int, default: 0
    change_column :counts, :final_stock, :int, default: 0
    change_column :counts, :accuracy_by_stock, :float, default: 0
  end
end
