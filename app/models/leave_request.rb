class LeaveRequest < ApplicationRecord
  belongs_to :user
  belongs_to :shift_day

  validates :user_id, uniqueness: { scope: :shift_day_id }
  validate :cannot_request_if_shift_assignment_exists

  private

  def cannot_request_if_shift_assignment_exists
    return if user.blank? || shift_day.blank?

    if ShiftAssignment.exists?(user_id: user_id, shift_day_id: shift_day_id)
      errors.add(:base, "すでに勤務が登録されているため希望休を登録できません")
    end
  end
end