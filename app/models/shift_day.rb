class ShiftDay < ApplicationRecord
  belongs_to :shift_period
  has_many :shift_assignments, dependent: :destroy

  enum day_type: { weekday: 0, saturday: 1, sunday: 2, holiday: 3 }

  validates :target_date, presence: true
  validates :target_date, uniqueness: { scope: :shift_period_id }
end
