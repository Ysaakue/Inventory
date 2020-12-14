class RenameClientToCompany < ActiveRecord::Migration[6.0]
  def change
    rename_table :clients, :companies
    rename_column :products, :client_id, :company_id
    rename_column :counts, :client_id, :company_id
    rename_column :imports, :client_id, :company_id
  end
end
