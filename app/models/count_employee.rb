class CountEmployee < ApplicationRecord
  belongs_to :count
  belongs_to :employee
end
