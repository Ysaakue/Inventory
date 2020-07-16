class CountProduct < ApplicationRecord
  belongs_to :count
  belongs_to :product
  has_many :results, class_name: 'Result'
end
