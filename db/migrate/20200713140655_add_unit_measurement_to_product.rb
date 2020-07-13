class AddUnitMeasurementToProduct < ActiveRecord::Migration[6.0]
  def change
    add_column :products, :unit_measurement, :integer, :default => 0
  end
end
