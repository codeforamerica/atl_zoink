class CreateAtlantaEndpoints < ActiveRecord::Migration
  def change
    create_table :atlanta_endpoints do |t|
      t.date :upload_date, :null => false
      t.datetime :requested_at
      t.datetime :response_received_at
      t.integer :response_code
      t.string :string_encoding
      t.integer :row_count
      t.datetime :extracted_at

      t.timestamps null: false
    end

    add_index :atlanta_endpoints, :upload_date, :unique => true
  end
end
