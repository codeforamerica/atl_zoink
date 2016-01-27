class CreateDataUrls < ActiveRecord::Migration
  def change
    create_table :data_urls do |t|
      t.date :upload_date, :null => false
      t.integer :response_code
      t.string :string_encoding
      t.integer :row_count
      t.boolean :extracted, :default => false
      t.boolean :extracted_at
      t.timestamps null: false
    end

    add_index :data_urls, :upload_date, :unique => true
  end
end
