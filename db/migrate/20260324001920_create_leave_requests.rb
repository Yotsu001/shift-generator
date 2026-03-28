class CreateLeaveRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :leave_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.references :shift_day, null: false, foreign_key: true
      t.string :note

      t.timestamps
    end

    add_index :leave_requests, [:user_id, :shift_day_id], unique: true
  end
end
