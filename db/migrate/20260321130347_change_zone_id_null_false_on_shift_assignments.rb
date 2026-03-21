class ChangeZoneIdNullFalseOnShiftAssignments < ActiveRecord::Migration[7.1]
  def change
    change_column_null :shift_assignments, :zone_id, false
  end
end
