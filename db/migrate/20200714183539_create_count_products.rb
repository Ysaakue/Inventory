class CreateCountProducts < ActiveRecord::Migration[6.0]
  def change
    create_table :count_products do |t|
      t.integer :product_id
      t.integer :count_id
      t.boolean :combined_count, default: false

      t.timestamps
    end
  end
end
