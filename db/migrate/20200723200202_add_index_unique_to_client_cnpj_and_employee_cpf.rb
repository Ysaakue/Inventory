class AddIndexUniqueToClientCnpjAndEmployeeCpf < ActiveRecord::Migration[6.0]
  def change
    add_index :clients, :cnpj, unique: true
    add_index :employees, :cpf, unique: true
  end
end
