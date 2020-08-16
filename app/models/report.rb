class Report < ApplicationRecord
  belongs_to :count

  enum status:[
    :generating,
    :completed
  ]
end
