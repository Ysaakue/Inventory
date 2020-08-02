class CreateImports < ActiveRecord::Migration[6.0]
  def change
    create_table :imports do |t|
      t.integer :client_id
      t.json :products
      t.string :description

      t.timestamps
    end
  end
end
