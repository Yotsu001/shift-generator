class CreateShiftAssignments < ActiveRecord::Migration[7.1]
  def change
    create_table :shift_assignments do |t|
      t.references :shift_day, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :zone_name, null: false
      t.integer :work_type, null: false, default: 0

      t.timestamps
    end
  add_index :shift_assignments, [:shift_day_id, :user_id], unique: true
  end
end
