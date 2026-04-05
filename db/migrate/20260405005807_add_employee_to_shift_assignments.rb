class AddEmployeeToShiftAssignments < ActiveRecord::Migration[7.0]
  def change
    add_reference :shift_assignments, :employee, null: true, foreign_key: true
  end
end