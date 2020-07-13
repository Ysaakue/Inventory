class Product < ApplicationRecord
  belongs_to :client

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
end
