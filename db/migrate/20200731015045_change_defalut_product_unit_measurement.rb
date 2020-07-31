class ChangeDefalutProductUnitMeasurement < ActiveRecord::Migration[6.0]
  def change
    change_column_default :products, :unit_measurement, "UN"
  end
end
