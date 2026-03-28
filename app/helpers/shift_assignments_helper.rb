module ShiftAssignmentsHelper
  def work_type_label(work_type)
    I18n.t("enums.shift_assignment.work_type.#{work_type}", default: work_type)
  end

  def day_type_label(day_type)
    I18n.t("enums.shift_day.day_type.#{day_type}", default: day_type)
  end

  def status_label(status)
    I18n.t("enums.shift_period.status.#{status}", default: status)
  end

  def work_type_options
    ShiftAssignment.work_types.keys.map do |key|
      [work_type_label(key), key]
    end
  end

  def work_type_badge_class(work_type)
    case work_type
    when "day_shift"
      "shift-badge shift-badge-day"
    when "night_shift"
      "shift-badge shift-badge-night"
    when "off_duty"
      "shift-badge shift-badge-off-duty"
    when "holiday"
      "shift-badge shift-badge-holiday"
    else
      "shift-badge"
    end
  end
end