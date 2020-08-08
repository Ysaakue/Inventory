class AddAccuracyToCount < ActiveRecord::Migration[6.0]
  def change
    add_column :counts, :accuracy, :float
  end
end
