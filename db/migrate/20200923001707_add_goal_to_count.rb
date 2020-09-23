class AddGoalToCount < ActiveRecord::Migration[6.0]
  def change
    add_column :counts, :goal, :integer
  end
end
