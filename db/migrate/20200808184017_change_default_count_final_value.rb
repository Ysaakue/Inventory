class ChangeDefaultCountFinalValue < ActiveRecord::Migration[6.0]
  def change
    change_column_default :counts, :final_value, 0
  end
end
