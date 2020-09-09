class CreateCountsEmployees < ActiveRecord::Migration[6.0]
  def change
    create_table :counts_employees do |t|
      t.integer :count_id
      t.integer :employee_id
      t.json :products

      t.timestamps
    end
  end
end
