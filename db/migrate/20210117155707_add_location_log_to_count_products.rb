class AddLocationLogToCountProducts < ActiveRecord::Migration[6.0]
  def change
    add_column :count_products, :location_log, :json
  end
end
