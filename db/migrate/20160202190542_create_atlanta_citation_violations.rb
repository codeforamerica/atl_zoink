class CreateAtlantaCitationViolations < ActiveRecord::Migration
  def change
    create_table :atlanta_citation_violations do |t|
      t.string :citation_guid, :null => false
      t.string :violation_code, :null => false
      t.timestamps null: false
    end

    add_index :atlanta_citation_violations, [:citation_guid, :violation_code], :unique => true, :name => "acv_composite_key"
  end
end
