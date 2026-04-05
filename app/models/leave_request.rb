class LeaveRequest < ApplicationRecord
  belongs_to :shift_day
  belongs_to :employee

  validates :employee, presence: true
  validate :cannot_request_if_shift_assignment_exists

  private

  def cannot_request_if_shift_assignment_exists
    return if employee.blank? || shift_day.blank?

    if ShiftAssignment.exists?(employee_id: employee.id, shift_day_id: shift_day.id)
      errors.add(:base, "すでに勤務が登録されているため希望休を登録できません")
    end
  end
end