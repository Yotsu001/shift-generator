class ShiftAssignment < ApplicationRecord
  belongs_to :shift_day
  belongs_to :user

  enum work_type: { day_shift: 0, night_shift: 1, off_duty: 2, holiday: 3 }

  validates :zone_name, presence: true
  validates :work_type, presence: true
  validates :user_id, uniqueness: { scope: :shift_day_id }
end
