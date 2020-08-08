class AddFieldsToCount < ActiveRecord::Migration[6.0]
  def change
    add_column :counts, :initial_value, :float
    add_column :counts, :final_value, :float
  end
end
