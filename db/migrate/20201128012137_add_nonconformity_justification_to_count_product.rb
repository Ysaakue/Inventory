class AddNonconformityJustificationToCountProduct < ActiveRecord::Migration[6.0]
  def change
    add_column :count_products, :nonconformity, :string, default: nil, null: true
  end
end
