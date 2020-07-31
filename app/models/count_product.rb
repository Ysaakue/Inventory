class CountProduct < ApplicationRecord
  belongs_to :count
  belongs_to :product
  has_many :results, class_name: 'Result'

  def as_json options={}
    {
      product_id: product.id,
      product_code: product.code,
      product_description: product.description,
      product_current_stock: product.current_stock,
      product_unit_measurement: product.unit_measurement,
      product_value: product.value,
      locations: (!product.location.blank? && !product.location["locations"].blank?)? product.location["locations"] : [],
      quantity_found: results
    }
  end
end
