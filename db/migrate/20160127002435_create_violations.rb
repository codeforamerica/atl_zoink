class CreateViolations < ActiveRecord::Migration
  def change
    create_table :violations do |t|
      t.string :guid #, :null => false
      t.string :description
      t.timestamps null: false
    end

    add_index :violations, :guid
  end
end
