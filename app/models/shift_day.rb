class ShiftDay < ApplicationRecord
  belongs_to :shift_period
  has_many :shift_assignments, dependent: :destroy
  has_many :leave_requests, dependent: :destroy

  enum day_type: { weekday: 0, saturday: 1, sunday: 2, holiday: 3 }

  validates :target_date, presence: true
  validates :target_date, uniqueness: { scope: :shift_period_id }

  def leave_requested_by?(employee)
    return false if employee.blank?

    leave_requests.exists?(employee_id: employee.id)
  end

  def assigned_to?(employee)
    return false if employee.blank?

    shift_assignments.exists?(employee_id: employee.id)
  end

  def assignment_for(employee)
    return nil if employee.blank?

    shift_assignments.find_by(employee_id: employee.id)
  end

  def leave_request_for(employee)
    return nil if employee.blank?

    leave_requests.find_by(employee_id: employee.id)
  end

  def assignable_for?(employee)
    return false if employee.blank?
    return false if leave_requested_by?(employee)
    return false if assigned_to?(employee)

    true
  end
end
