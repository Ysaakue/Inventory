class CreateJoinTableCountEmployee < ActiveRecord::Migration[6.0]
  def change
    create_join_table :employees, :counts do |t|
      t.index [:employee_id, :count_id]
      t.index [:count_id, :employee_id]
    end
  end
end
