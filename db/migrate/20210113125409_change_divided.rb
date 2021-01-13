class ChangeDivided < ActiveRecord::Migration[6.0]
  def change
    remove_column :counts, :divided
    add_column :counts, :divide_status, :integer, default: 0
  end
end
