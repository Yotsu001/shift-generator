class CreateShiftDays < ActiveRecord::Migration[7.1]
  def change
    create_table :shift_days do |t|
      t.references :shift_period, null: false, foreign_key: true
      t.date :target_date, null: false
      t.integer :day_type, null: false, default: 0

      t.timestamps
    end

  add_index :shift_days, [:shift_period_id, :target_date], unique: true
  end
end
