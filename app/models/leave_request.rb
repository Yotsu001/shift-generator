class LeaveRequest < ApplicationRecord
  belongs_to :shift_day
  belongs_to :employee

  validates :employee, presence: true
  validate :cannot_request_if_shift_assignment_exists
  validate :employee_must_belong_to_shift_period_owner

  private

  def cannot_request_if_shift_assignment_exists
    return if employee.blank? || shift_day.blank?

    if ShiftAssignment.exists?(employee_id: employee.id, shift_day_id: shift_day.id)
      errors.add(:base, "すでに勤務が登録されているため希望休を登録できません")
    end
  end

  def employee_must_belong_to_shift_period_owner
    return if employee.blank? || shift_day.blank?
    return if shift_day.shift_period.blank?
    return if employee.user_id == shift_day.shift_period.user_id

    errors.add(:employee, "はこのシフト期間の作成者に属するスタッフを選択してください")
  end
end