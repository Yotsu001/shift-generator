class ChangeUserIdNullableOnShiftAssignmentsAndLeaveRequests < ActiveRecord::Migration[7.0]
  def up
    change_column_null :shift_assignments, :user_id, true
    change_column_null :leave_requests, :user_id, true
  end

  def down
    if ShiftAssignment.where(user_id: nil).exists?
      raise ActiveRecord::IrreversibleMigration, "shift_assignments.user_id に NULL があるため戻せません"
    end

    if LeaveRequest.where(user_id: nil).exists?
      raise ActiveRecord::IrreversibleMigration, "leave_requests.user_id に NULL があるため戻せません"
    end

    change_column_null :shift_assignments, :user_id, false
    change_column_null :leave_requests, :user_id, false
  end
end