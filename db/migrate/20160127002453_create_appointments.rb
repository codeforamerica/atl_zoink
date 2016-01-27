class CreateAppointments < ActiveRecord::Migration
  def change
    create_table :appointments do |t|
      t.integer :citation_id, :null => false
      t.string :defendant_full_name
      t.string :room
      t.string :date
      t.string :time
      t.timestamps null: false
    end

    add_index :appointments, :citation_id
  end
end
