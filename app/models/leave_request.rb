class LeaveRequest < ApplicationRecord
  belongs_to :user
  belongs_to :shift_day

  validates :user_id, uniqueness: { scope: :shift_day_id }
end
