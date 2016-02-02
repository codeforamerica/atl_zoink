class CreateAtlantaCitations < ActiveRecord::Migration
  def change
    create_table :atlanta_citations do |t|
      t.string :guid, :null => false
      t.string :defendant_full_name
      t.string :location
      t.boolean :payable
      t.timestamps null: false
    end

    add_index :atlanta_citations, :guid, :unique => true
  end
end
