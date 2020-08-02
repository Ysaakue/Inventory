class Product < ApplicationRecord
  belongs_to :client
  has_many :counts_products, class_name: "CountProduct"

  def as_json options={}
    import = if options && options.key?(:import)
      options[:import]
    end
    if import
      {
        description: description,
        code: code,
        current_stock: current_stock,
        value: value,
        unit_measurement: unit_measurement
      }
    else
      {
        id: id,
        code: code,
        description: description,
        current_stock: current_stock,
        unit_measurement: unit_measurement,
        value: value,
        active: active,
        client: client.fantasy_name,
        location: location
      }
    end
  end
end
