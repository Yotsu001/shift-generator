class UpdateAssignmentAndLeaveRequestIndexes < ActiveRecord::Migration[7.1]
  def up
    if index_exists?(:shift_assignments, [:shift_day_id, :user_id], unique: true)
      remove_index :shift_assignments, column: [:shift_day_id, :user_id]
    end

    unless index_exists?(:shift_assignments, [:shift_day_id, :employee_id], unique: true)
      add_index :shift_assignments, [:shift_day_id, :employee_id], unique: true
    end

    unless index_exists?(:shift_assignments, [:shift_day_id, :work_type])
      add_index :shift_assignments, [:shift_day_id, :work_type]
    end

    if index_exists?(:leave_requests, [:user_id, :shift_day_id], unique: true)
      remove_index :leave_requests, column: [:user_id, :shift_day_id]
    end

    unless index_exists?(:leave_requests, [:shift_day_id, :employee_id], unique: true)
      add_index :leave_requests, [:shift_day_id, :employee_id], unique: true
    end
  end

  def down
    if index_exists?(:leave_requests, [:shift_day_id, :employee_id], unique: true)
      remove_index :leave_requests, column: [:shift_day_id, :employee_id]
    end

    unless index_exists?(:leave_requests, [:user_id, :shift_day_id], unique: true)
      add_index :leave_requests, [:user_id, :shift_day_id], unique: true
    end

    if index_exists?(:shift_assignments, [:shift_day_id, :work_type])
      remove_index :shift_assignments, column: [:shift_day_id, :work_type]
    end

    if index_exists?(:shift_assignments, [:shift_day_id, :employee_id], unique: true)
      remove_index :shift_assignments, column: [:shift_day_id, :employee_id]
    end

    unless index_exists?(:shift_assignments, [:shift_day_id, :user_id], unique: true)
      add_index :shift_assignments, [:shift_day_id, :user_id], unique: true
    end
  end
end
