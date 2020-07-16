class Product < ApplicationRecord
  belongs_to :client
  has_many :counts_products, class_name: "CountProduct"
  
  enum unit_measurement: {
    PTE: 0,
    KG: 1,
    MT: 2,
    UN: 3,
    LT: 4,
    CX: 5,
    ML: 6,
    PC: 7,
    FD: 8,
    FR: 9
  }

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
