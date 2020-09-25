class AddSuspendedToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :suspended, :boolean, default: false
  end
end
