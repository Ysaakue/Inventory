class AddInThirdCountToCountsEmployees < ActiveRecord::Migration[6.0]
  def change
    add_column :counts_employees, :in_third_count, :boolean, default: false
  end
end
