class ShiftAssignment < ApplicationRecord
  belongs_to :shift_day
  belongs_to :employee
  belongs_to :zone, optional: true

  enum :work_type, {
    day_shift: 0,
    middle_shift: 1,
    night_shift: 2,
    saturday_off: 3,
    sunday_off: 4,
    holiday: 5,
    national_holiday: 6
  }

  validates :employee, presence: true
  validates :work_type, presence: true

  before_validation :clear_zone_when_not_allowed

  validate :zone_presence_by_work_type
  validate :zone_must_be_assignable_for_employee
  validate :one_middle_shift_per_weekday
  validate :weekend_work_type_limit
  validate :cannot_assign_if_leave_requested
  validate :employee_must_belong_to_shift_period_owner

  delegate :name, to: :employee, prefix: true, allow_nil: true

  private

  def clear_zone_when_not_allowed
    self.zone = nil unless zone_allowed?
  end

  def zone_allowed?
    return false if work_type.blank?
    return false if weekend_or_holiday?

    day_shift? || middle_shift? || night_shift?
  end

  def zone_presence_by_work_type
    return if work_type.blank?

    if day_shift? || night_shift?
      if weekend_or_holiday?
        errors.add(:zone, "は土日祝勤務では指定できません") if zone.present?
      else
        errors.add(:zone, "を指定してください") if zone.blank?
      end
    elsif middle_shift?
      errors.add(:zone, "は土日祝勤務では指定できません") if weekend_or_holiday? && zone.present?
    elsif saturday_off? || sunday_off? || holiday? || national_holiday?
      errors.add(:zone, "は指定できません") if zone.present?
    end
  end

  def zone_must_be_assignable_for_employee
    return if employee.blank? || zone.blank?
    return unless day_shift? || middle_shift? || night_shift?
    return unless employee.respond_to?(:zones)
    return if employee.zones.include?(zone)

    errors.add(:zone, "はこの従業員の担当可能区ではありません")
  end

  def one_middle_shift_per_weekday
    return unless middle_shift?
    return if weekend_or_holiday?

    relation = ShiftAssignment.where(
      shift_day_id: shift_day_id,
      work_type: work_type
    )
    relation = relation.where.not(id: id) if persisted?

    if relation.exists?
      errors.add(:work_type, "は平日で1人までです")
    end
  end

  def weekend_work_type_limit
    return unless weekend_or_holiday?
    return unless day_shift? || middle_shift?

    relation = ShiftAssignment.where(
      shift_day_id: shift_day_id,
      work_type: work_type
    )
    relation = relation.where.not(id: id) if persisted?

    if relation.exists?
      errors.add(:work_type, "は土日祝で1人までです")
    end
  end

  def cannot_assign_if_leave_requested
    return if employee.blank?
    return if shift_day.blank?
    return unless day_shift? || middle_shift? || night_shift?

    if LeaveRequest.exists?(employee_id: employee_id, shift_day_id: shift_day_id)
      errors.add(:base, "希望休が登録されているため勤務を割り当てできません")
    end
  end

  def employee_must_belong_to_shift_period_owner
    return if employee.blank? || shift_day.blank?
    return if shift_day.shift_period.blank?
    return if employee.user_id == shift_day.shift_period.user_id

    errors.add(:employee, "はこのシフト期間の作成者に属するスタッフを選択してください")
  end

  def weekend_or_holiday?
    return false if shift_day.blank?

    shift_day.saturday? || shift_day.sunday? || shift_day.holiday?
  end
end
