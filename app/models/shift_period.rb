class ShiftPeriod < ApplicationRecord
  has_many :shift_days, dependent: :destroy

  enum status: { draft: 0, published: 1, locked: 2 }

  validates :name, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validate :end_date_after_start_date

  private

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?
    return if end_date >= start_date

    errors.add(:end_date, "は開始日以降の日付を選択してください")
  end
end
