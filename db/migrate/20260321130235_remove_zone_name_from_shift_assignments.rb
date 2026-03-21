class RemoveZoneNameFromShiftAssignments < ActiveRecord::Migration[7.1]
  def change
    remove_column :shift_assignments, :zone_name, :string
  end
end
