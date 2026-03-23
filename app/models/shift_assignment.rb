class ShiftAssignment < ApplicationRecord
  belongs_to :shift_day
  belongs_to :user
  belongs_to :zone, optional: true

  enum :work_type, { day_shift: 0, night_shift: 1, off_duty: 2, holiday: 3 }

  validates :work_type, presence: true
  validates :user_id, uniqueness: { scope: :shift_day_id }

  validate :zone_presence_by_work_type
  validate :zone_must_be_assignable_for_user
  validate :only_one_mixed_zone_per_day
  validate :weekend_work_type_limit

  private

  def zone_presence_by_work_type
    if day_shift? || night_shift?
      errors.add(:zone, "を選択してください") if zone.blank?
    elsif off_duty? || holiday?
      errors.add(:zone, "は休みの勤務区分では選択できません") if zone.present?
    end
  end

  def zone_must_be_assignable_for_user
    return if user.blank? || zone.blank?
    return unless day_shift? || night_shift?
    return if user.zones.include?(zone)

    errors.add(:zone, "はこのユーザーの担当可能区ではありません")
  end

  def only_one_mixed_zone_per_day
    return if shift_day.blank? || zone.blank?
    return unless day_shift? || night_shift?
    return unless zone.name == "混合"

    existing_assignments = shift_day.shift_assignments.where(zone_id: zone.id).where.not(id: id)
    return if existing_assignments.blank?

    errors.add(:zone, "は1日1人までです")
  end

  def weekend_work_type_limit
    return if shift_day.blank?
    return unless shift_day.saturday? || shift_day.sunday?

    unless day_shift? || night_shift?
      errors.add(:work_type, "は土日では日勤または夜勤のみ登録できます")
      return
    end

    existing_same_type = shift_day.shift_assignments
                                  .where(work_type: work_type)
                                  .where.not(id: id)

    return if existing_same_type.blank?

    if day_shift?
      errors.add(:work_type, "の日勤は土日1人までです")
    elsif night_shift?
      errors.add(:work_type, "の夜勤は土日1人までです")
    end
  end
end