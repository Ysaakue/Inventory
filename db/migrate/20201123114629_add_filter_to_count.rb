class AddFilterToCount < ActiveRecord::Migration[6.0]
  def change
    add_column :counts, :filter, :integer, default: 0
  end
end
