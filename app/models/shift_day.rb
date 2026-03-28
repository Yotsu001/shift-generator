class ShiftDay < ApplicationRecord
  belongs_to :shift_period
  has_many :shift_assignments, dependent: :destroy
  has_many :leave_requests, dependent: :destroy

  enum day_type: { weekday: 0, saturday: 1, sunday: 2, holiday: 3 }

  validates :target_date, presence: true
  validates :target_date, uniqueness: { scope: :shift_period_id }

  def leave_requested_by?(user)
    return false if user.blank?

    leave_requests.exists?(user_id: user.id)
  end

  def assigned_to?(user)
    return false if user.blank?

    shift_assignments.exists?(user_id: user.id)
  end

  def assignment_for(user)
    return nil if user.blank?

    shift_assignments.find_by(user_id: user.id)
  end

  def leave_request_for(user)
    return nil if user.blank?

    leave_requests.find_by(user_id: user.id)
  end

  def assignable_for?(user)
    return false if user.blank?
    return false if leave_requested_by?(user)
    return false if assigned_to?(user)

    true
  end
end
