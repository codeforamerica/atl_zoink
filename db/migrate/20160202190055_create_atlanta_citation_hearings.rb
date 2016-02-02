class CreateAtlantaCitationHearings < ActiveRecord::Migration
  def change
    create_table :atlanta_citation_hearings do |t|
      t.string :citation_guid, :null => false
      t.datetime :appointment_at, :null => false
      t.string :room
      t.timestamps null: false
    end

    add_index :atlanta_citation_hearings, [:citation_guid, :appointment_at], :unique => true, :name => "ach_composite_key"
  end
end
