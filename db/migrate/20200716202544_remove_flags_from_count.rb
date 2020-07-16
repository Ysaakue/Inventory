class RemoveFlagsFromCount < ActiveRecord::Migration[6.0]
  def change
    remove_column :counts, :flags, :string
  end
end
