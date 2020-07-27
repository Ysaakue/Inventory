class ChangeUnitMeasurementToString < ActiveRecord::Migration[6.0]
  def change
    change_column :products, :unit_measurement, :string
  end
end
