class ChangeZoneIdNullTrueOnShiftAssignments < ActiveRecord::Migration[7.1]
  def change
    change_column_null :shift_assignments, :zone_id, true
  end
end
