class BackfillEmployeesFromUsers < ActiveRecord::Migration[7.0]
  def up
    User.reset_column_information
    Employee.reset_column_information
    ShiftAssignment.reset_column_information
    LeaveRequest.reset_column_information

    User.find_each do |user|
      employee = Employee.find_or_initialize_by(user_id: user.id)
      employee.name = user.name
      employee.active = true if employee.active.nil?
      employee.display_order = user.id if employee.display_order.nil?
      employee.mixed_zone_enabled = false if employee.mixed_zone_enabled.nil?
      employee.weekend_work_enabled = true if employee.weekend_work_enabled.nil?
      employee.save!
    end

    ShiftAssignment.find_each do |assignment|
      next if assignment.user_id.blank?

      employee = Employee.find_by(user_id: assignment.user_id)
      assignment.update_columns(employee_id: employee.id) if employee.present?
    end

    LeaveRequest.find_each do |leave_request|
      next if leave_request.user_id.blank?

      employee = Employee.find_by(user_id: leave_request.user_id)
      leave_request.update_columns(employee_id: employee.id) if employee.present?
    end
  end

  def down
    ShiftAssignment.update_all(employee_id: nil)
    LeaveRequest.update_all(employee_id: nil)
    Employee.delete_all
  end

  class User < ApplicationRecord
    self.table_name = "users"
  end

  class Employee < ApplicationRecord
    self.table_name = "employees"
  end

  class ShiftAssignment < ApplicationRecord
    self.table_name = "shift_assignments"
  end

  class LeaveRequest < ApplicationRecord
    self.table_name = "leave_requests"
  end
end