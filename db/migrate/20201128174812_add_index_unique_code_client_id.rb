class AddIndexUniqueCodeClientId < ActiveRecord::Migration[6.0]
  def change
    add_index :products, [:code,:client_id], unique: true
  end
end
