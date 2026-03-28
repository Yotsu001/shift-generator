module ShiftAssignmentsHelper
  def work_type_label(work_type)
    case work_type
    when "day_shift"
      "日勤"
    when "night_shift"
      "夜勤"
    when "off_duty"
      "非番"
    when "holiday"
      "休日"
    else
      work_type
    end
  end

  def day_type_label(day_type)
    case day_type
    when "weekday"
      "平日"
    when "saturday"
      "土曜"
    when "sunday"
      "日曜"
    when "holiday"
      "祝日"
    else
      day_type
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