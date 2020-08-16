class CreateReports < ActiveRecord::Migration[6.0]
  def change
    create_table :reports do |t|
      t.string :filename
      t.string :content_type
      t.string :file_contents
      t.integer :count_id

      t.timestamps
    end
  end
end
