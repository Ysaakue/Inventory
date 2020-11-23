class AddInputOutputToProduct < ActiveRecord::Migration[6.0]
  def change
    add_column :products, :input, :integer, defalt: 0
    add_column :products, :output, :integer, defalt: 0
  end
end
