class AddInitialStockAndFinalStockAndAccuracyByStockToCount < ActiveRecord::Migration[6.0]
  def change
    add_column :counts, :initial_stock, :integer
    add_column :counts, :final_stock, :integer
    add_column :counts, :accuracy_by_stock, :float
  end
end
