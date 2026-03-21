class CreateShiftPeriods < ActiveRecord::Migration[7.1]
  def change
    create_table :shift_periods do |t|
      t.string :name, null: false
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :shift_periods, [:start_date, :end_date], unique: true
  end
end
