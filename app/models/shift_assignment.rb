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
  validate :cannot_assign_if_leave_requested

  private

  def zone_presence_by_work_type
    if day_shift? || night_shift?
      if weekend_or_holiday_shift_day?
        errors.add(:zone, "は土日祝の日勤・夜勤では選択できません") if zone.present?
      else
        errors.add(:zone, "を選択してください") if zone.blank?
      end
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
    return unless weekend_or_holiday_shift_day?

    unless day_shift? || night_shift?
      errors.add(:work_type, "は土日祝では日勤または夜勤のみ登録できます")
      return
    end

    existing_same_type = shift_day.shift_assignments
                                  .where(work_type: work_type)
                                  .where.not(id: id)

    return if existing_same_type.blank?

    if day_shift?
      errors.add(:work_type, "の日勤は土日祝1人までです")
    elsif night_shift?
      errors.add(:work_type, "の夜勤は土日祝1人までです")
    end
  end

  def cannot_assign_if_leave_requested
    return if user.blank? || shift_day.blank?

    if LeaveRequest.exists?(user_id: user_id, shift_day_id: shift_day_id)
      errors.add(:base, "希望休が登録されているため勤務を登録できません")
    end
  end

  def weekend_or_holiday_shift_day?
    shift_day.present? && (shift_day.saturday? || shift_day.sunday? || shift_day.holiday?)
  end
end