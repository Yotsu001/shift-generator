class ShiftAssignment < ApplicationRecord
  belongs_to :shift_day
  belongs_to :user
  belongs_to :zone

  enum :work_type, { day_shift: 0, night_shift: 1, off_duty: 2, holiday: 3 }

  validates :work_type, presence: true
  validates :user_id, uniqueness: { scope: :shift_day_id }
  validate :zone_must_be_assignable_for_user
  validate :only_one_mixed_zone_per_day
  validate :weekend_assignment_limit

  private

  def zone_must_be_assignable_for_user
    return if user.blank? || zone.blank?
    return if user.zones.include?(zone)

    errors.add(:zone, "はこのユーザーの担当可能区ではありません")
  end

  def only_one_mixed_zone_per_day
    return if shift_day.blank? || zone.blank?
    return unless zone.name == "混合"

    existing_assignments = shift_day.shift_assignments.where(zone_id: zone.id).where.not(id: id)
    return if existing_assignments.blank?

    errors.add(:zone, "は1日1人までです")
  end

  def weekend_assignment_limit
    return if shift_day.blank?
    return unless shift_day.saturday? || shift_day.sunday?

    existing_count = shift_day.shift_assignments.where.not(id: id).count
    return if existing_count < 2
    
    errors.add(:base, "土日 の割当は2人までです")
  end
end