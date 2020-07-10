class CreateClients < ActiveRecord::Migration[6.0]
  def change
    create_table :clients do |t|
      t.string :cnpj
      t.string :company_name
      t.string :fantasy_name
      t.string :state_registration
      t.string :email
      t.string :contact_name_telephone
      t.string :telephone_number
      t.string :contact_name_cell_phone
      t.string :cell_phone_number
      t.string :street_name_address
      t.integer :number_address
      t.string :complement_address
      t.string :neighborhood_address
      t.string :postal_code_address
      t.integer :state_id
      t.integer :city_id

      t.timestamps
    end
  end
end
