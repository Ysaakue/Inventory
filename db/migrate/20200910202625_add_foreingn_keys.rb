class AddForeingnKeys < ActiveRecord::Migration[6.0]
  def change
    #city
    add_foreign_key :cities, :states, on_delete: :cascade

    #client
    add_foreign_key :clients, :cities
    add_foreign_key :clients, :states

    #count_employee
    add_foreign_key :counts_employees, :counts, on_delete: :cascade
    add_foreign_key :counts_employees, :employees, on_delete: :cascade

    #count_product
    add_foreign_key :count_products, :counts, on_delete: :cascade
    add_foreign_key :count_products, :products, on_delete: :cascade

    #count
    add_foreign_key :counts, :clients, on_delete: :cascade

    #import
    add_foreign_key :imports, :clients, on_delete: :cascade

    #product
    add_foreign_key :products, :clients, on_delete: :cascade

    #report
    add_foreign_key :reports, :counts, on_delete: :cascade

    #result
    add_foreign_key :results, :count_products, on_delete: :cascade
    add_foreign_key :results, :employees
  end
end
