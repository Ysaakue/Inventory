class CountEmployee < ApplicationRecord
  belongs_to :count
  belongs_to :employee

  def set_employees_to_third_count(count,employee_ids)
    sql = "update counts_employees set in_third_count = true where count_id = #{count.id} and employee_id in (#{employee_ids.join(',')})"
    result = ActiveRecord::Base.connection.execute(sql)
    count.delegate_employee_to_third_count
  end

  handle_asynchronously :set_employees_to_third_count
end
