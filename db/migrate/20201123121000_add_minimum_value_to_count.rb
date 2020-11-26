class AddMinimumValueToCount < ActiveRecord::Migration[6.0]
  def change
    add_column :counts, :minimum_value, :integer, default: 0
  end
end
