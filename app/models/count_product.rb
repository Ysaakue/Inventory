class CountProduct < ApplicationRecord
  belongs_to :count
  belongs_to :product
  has_many :results, class_name: 'Result'

  def as_json options={}
    {
      id: id,
      product_id: product.id,
      code: product.code,
      description: product.description,
      current_stock: product.current_stock,
      unit_measurement: product.unit_measurement,
      value: product.value,
      client: product.client.fantasy_name,
      locations: product.location["locations"],
      quantity_found: results
    }
  end
end
