class ShiftPeriod < ApplicationRecord
  belongs_to :user

  has_many :shift_days, dependent: :destroy
  has_many :shift_assignments, through: :shift_days
  has_many :leave_requests, through: :shift_days

  enum status: { draft: 0, locked: 1 }

  validates :name, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :start_date, uniqueness: { scope: [:user_id, :end_date] }
  validate :end_date_after_start_date

  after_create :generate_shift_days

  def self.detect_day_type_for(date)
    case date.wday
    when 0
      :sunday
    when 6
      :saturday
    else
      national_holiday?(date) ? :holiday : :weekday
    end
  end

  def self.national_holiday?(date)
    defined?(HolidayJp) && HolidayJp.holiday?(date)
  end

  def rebuild_shift_days!
    shift_days.destroy_all
    generate_shift_days
  end

  def refresh_day_types!
    updated_count = 0

    shift_days.find_each do |shift_day|
      expected_day_type = self.class.detect_day_type_for(shift_day.target_date)
      next if shift_day.day_type == expected_day_type.to_s

      shift_day.update!(day_type: expected_day_type)
      updated_count += 1
    end

    updated_count
  end

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
    self.class.detect_day_type_for(date)
  end
end
