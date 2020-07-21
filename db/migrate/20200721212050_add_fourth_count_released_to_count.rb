class AddFourthCountReleasedToCount < ActiveRecord::Migration[6.0]
  def change
    add_column :counts, :fourth_count_released, :boolean, default: false
  end
end
