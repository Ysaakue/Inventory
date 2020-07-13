class AddDimensionsToClient < ActiveRecord::Migration[6.0]
  def change
    add_column :clients, :dimensions, :json
  end
end
