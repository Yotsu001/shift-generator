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
end