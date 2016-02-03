class CreateAtlantaViolations < ActiveRecord::Migration
  def change
    create_table :atlanta_violations do |t|
      t.string :code, :null => false
      t.string :description
      t.timestamps null: false
    end

    add_index :atlanta_violations, :code, :unique => true
  end
end
