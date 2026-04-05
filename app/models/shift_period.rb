class ShiftPeriod < ApplicationRecord
  has_many :shift_days, dependent: :destroy
  has_many :shift_assignments, through: :shift_days
  has_many :leave_requests, through: :shift_days

  enum status: { draft: 0, published: 1, locked: 2 }

  validates :name, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validate :end_date_after_start_date

  after_create :generate_shift_days

  private

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?
    return if end_date >= start_date

    errors.add(:end_date, "は開始日以降の日付を選択してください")
  end

  def generate_shift_days
    (start_date..end_date).each do |date|
      shift_days.create!(
        target_date: date,
        day_type: detect_day_type(date)
      )
    end
  end

  def detect_day_type(date)
    case date.wday
    when 0
      :sunday
    when 6
      :saturday
    else
      :weekday
    end
  end
end