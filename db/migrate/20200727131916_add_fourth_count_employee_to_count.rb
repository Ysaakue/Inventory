class AddFourthCountEmployeeToCount < ActiveRecord::Migration[6.0]
  def change
    add_column :counts, :fourth_count_employee, :integer
  end
end
