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

  validate :zone_presence_by_work_type
  validate :zone_must_be_assignable_for_employee
  validate :only_one_mixed_zone_per_day
  validate :weekend_work_type_limit
  validate :cannot_assign_if_leave_requested

  delegate :name, to: :employee, prefix: true, allow_nil: true

  private

  def zone_presence_by_work_type
    return if work_type.blank?

    if day_shift? || middle_shift? || night_shift?
      if weekend_or_holiday?
        errors.add(:zone, "は土日祝勤務では指定できません") if zone.present?
      else
        errors.add(:zone, "を指定してください") if zone.blank?
      end
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

  def only_one_mixed_zone_per_day
    return if zone.blank?
    return unless zone_mixed?

    relation = ShiftAssignment.where(
      shift_day_id: shift_day_id,
      zone_id: zone_id
    )
    relation = relation.where.not(id: id) if persisted?

    if relation.exists?
      errors.add(:zone, "混合区は1日1人までです")
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

  def weekend_or_holiday?
    return false if shift_day.blank?

    shift_day.saturday? || shift_day.sunday? || shift_day.holiday?
  end

  def zone_mixed?
    zone.respond_to?(:name) && zone.name == "混合"
  end
end