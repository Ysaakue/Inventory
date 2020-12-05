class CreateRoles < ActiveRecord::Migration[6.0]
  def change
    create_table :roles do |t|
      t.string :description
      t.json :permissions

      t.timestamps
    end
  end
end
