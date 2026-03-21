class AddZoneToShiftAssignments < ActiveRecord::Migration[7.1]
  def change
    add_reference :shift_assignments, :zone, foreign_key: true
  end
end
