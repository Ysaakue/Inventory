class Product < ApplicationRecord
  belongs_to :client
  has_many :counts_products, class_name: "CountProduct"

  def as_json options={}
    {
      id: id,
      code: code,
      description: description,
      current_stock: current_stock,
      unit_measurement: unit_measurement,
      value: value,
      client: client.fantasy_name,
      location: location,
    }
  end
end
