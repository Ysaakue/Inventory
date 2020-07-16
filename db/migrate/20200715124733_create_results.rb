class CreateResults < ActiveRecord::Migration[6.0]
  def change
    create_table :results do |t|
      t.integer :order
      t.integer :quantity_found, default: -1
      t.integer :count_product_id
      t.integer :employee_id

      t.timestamps
    end
  end
end
