class CountEmployee < ApplicationRecord
  belongs_to :count
  belongs_to :employee

  def self.set_employees_to_third_count(employee_ids)
    sql = "update counts_employees set in_third_count = true where count_id = #{count.id} and employee_id in (#{employee_ids.join(',')})"
    result = ActiveRecord::Base.connection.execute(sql)
  end
end
