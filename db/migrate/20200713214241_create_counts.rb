class CreateCounts < ActiveRecord::Migration[6.0]
  def change
    create_table :counts do |t|
      t.date :date
      t.integer :status, default: 0
      t.json :flags
      t.integer :client_id

      t.timestamps
    end
  end
end
