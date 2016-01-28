class CreateAtlantaEndpointObjects < ActiveRecord::Migration
  def change
    create_table :atlanta_endpoint_objects do |t|
      t.integer :endpoint_id, :null => false
      t.string :date
      t.string :defendant
      t.string :location
      t.string :room
      t.string :time
      t.string :guid
      t.string :violation
      t.string :description
      t.boolean :payable
      #t.timestamps null: false
    end

    add_index :atlanta_endpoint_objects, :endpoint_id
  end
end
