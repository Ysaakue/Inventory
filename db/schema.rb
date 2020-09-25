# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_09_25_151825) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "btree_gin"
  enable_extension "btree_gist"
  enable_extension "citext"
  enable_extension "cube"
  enable_extension "dblink"
  enable_extension "dict_int"
  enable_extension "dict_xsyn"
  enable_extension "earthdistance"
  enable_extension "fuzzystrmatch"
  enable_extension "hstore"
  enable_extension "intarray"
  enable_extension "ltree"
  enable_extension "pg_stat_statements"
  enable_extension "pg_trgm"
  enable_extension "pgcrypto"
  enable_extension "pgrowlocks"
  enable_extension "pgstattuple"
  enable_extension "plpgsql"
  enable_extension "tablefunc"
  enable_extension "unaccent"
  enable_extension "uuid-ossp"
  enable_extension "xml2"

  create_table "cities", force: :cascade do |t|
    t.string "name"
    t.integer "state_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "clients", force: :cascade do |t|
    t.string "cnpj"
    t.string "company_name"
    t.string "fantasy_name"
    t.string "state_registration"
    t.string "email"
    t.string "contact_name_telephone"
    t.string "telephone_number"
    t.string "contact_name_cell_phone"
    t.string "cell_phone_number"
    t.string "street_name_address"
    t.integer "number_address"
    t.string "complement_address"
    t.string "neighborhood_address"
    t.string "postal_code_address"
    t.integer "state_id"
    t.integer "city_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.json "dimensions"
    t.index ["cnpj"], name: "index_clients_on_cnpj", unique: true
  end

  create_table "count_products", force: :cascade do |t|
    t.integer "product_id"
    t.integer "count_id"
    t.boolean "combined_count", default: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.float "total_value"
    t.float "percentage_result", default: 0.0
    t.float "final_total_value", default: 0.0
    t.float "percentage_result_value", default: 0.0
    t.boolean "ignore", default: false
    t.string "justification"
  end

  create_table "counts", force: :cascade do |t|
    t.date "date"
    t.integer "status", default: 0
    t.integer "client_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "fourth_count_released", default: false
    t.integer "fourth_count_employee"
    t.integer "products_quantity_to_count"
    t.float "initial_value"
    t.float "final_value", default: 0.0
    t.float "accuracy", default: 0.0
    t.boolean "divided", default: false
    t.integer "goal"
  end

  create_table "counts_employees", force: :cascade do |t|
    t.integer "count_id"
    t.integer "employee_id"
    t.json "products"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "employees", force: :cascade do |t|
    t.string "name"
    t.string "cpf"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["cpf"], name: "index_employees_on_cpf", unique: true
  end

  create_table "imports", force: :cascade do |t|
    t.integer "client_id"
    t.json "products"
    t.string "description"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "products", force: :cascade do |t|
    t.string "description"
    t.string "code"
    t.integer "current_stock"
    t.float "value"
    t.json "location"
    t.integer "client_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "unit_measurement", default: "UN"
    t.boolean "active", default: true
    t.boolean "new", default: true
  end

  create_table "reports", force: :cascade do |t|
    t.string "filename"
    t.string "content_type"
    t.string "file_contents"
    t.integer "count_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "status"
  end

  create_table "results", force: :cascade do |t|
    t.integer "order"
    t.integer "quantity_found", default: -1
    t.integer "count_product_id"
    t.integer "employee_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "states", force: :cascade do |t|
    t.string "name"
    t.string "federation_unity"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "provider", default: "email", null: false
    t.string "uid", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.boolean "allow_password_change", default: false
    t.datetime "remember_created_at"
    t.string "name"
    t.string "nickname"
    t.string "image"
    t.string "email"
    t.text "tokens"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.boolean "admin", default: false
    t.integer "client_id"
    t.boolean "suspended", default: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true
  end

  add_foreign_key "cities", "states", on_delete: :cascade
  add_foreign_key "clients", "cities"
  add_foreign_key "clients", "states"
  add_foreign_key "count_products", "counts", on_delete: :cascade
  add_foreign_key "count_products", "products", on_delete: :cascade
  add_foreign_key "counts", "clients", on_delete: :cascade
  add_foreign_key "counts_employees", "counts", on_delete: :cascade
  add_foreign_key "counts_employees", "employees", on_delete: :cascade
  add_foreign_key "imports", "clients", on_delete: :cascade
  add_foreign_key "products", "clients", on_delete: :cascade
  add_foreign_key "reports", "counts", on_delete: :cascade
  add_foreign_key "results", "count_products", on_delete: :cascade
  add_foreign_key "results", "employees"
end
