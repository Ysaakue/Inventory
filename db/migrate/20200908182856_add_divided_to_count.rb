class AddDividedToCount < ActiveRecord::Migration[6.0]
  def change
    add_column :counts, :divided, :boolean, default: false
  end
end
