class DropCountsEMployees < ActiveRecord::Migration[6.0]
  def change
    drop_table :counts_employees
  end
end
