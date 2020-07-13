class CreateProducts < ActiveRecord::Migration[6.0]
  def change
    create_table :products do |t|
      t.string :description
      t.string :code
      t.integer :current_stock
      t.float :value
      t.json :location
      t.integer :client_id

      t.timestamps
    end
  end
end
