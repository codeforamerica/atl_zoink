class CreateCitations < ActiveRecord::Migration
  def change
    create_table :citations do |t|
      t.string :guid, :null => false
      t.integer :violation_id, :null => false
      t.string :location
      t.boolean :payable
      t.timestamps null: false
    end

    add_index :citations, :guid
    add_index :citations, :violation_id
  end
end
