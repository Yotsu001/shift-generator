class RemoveUnusedUserReferencesFromAssignmentsAndLeaveRequests < ActiveRecord::Migration[7.1]
  def up
    remove_reference :shift_assignments, :user, foreign_key: true, index: true if column_exists?(:shift_assignments, :user_id)
    remove_reference :leave_requests, :user, foreign_key: true, index: true if column_exists?(:leave_requests, :user_id)
  end

  def down
    add_reference :shift_assignments, :user, foreign_key: true, null: true unless column_exists?(:shift_assignments, :user_id)
    add_reference :leave_requests, :user, foreign_key: true, null: true unless column_exists?(:leave_requests, :user_id)
  end
end
