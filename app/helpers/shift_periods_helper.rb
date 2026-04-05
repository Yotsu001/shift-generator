module ShiftPeriodsHelper
  def shift_days(shift_period)
    shift_period.shift_days.order(:target_date)
  end

  def holiday_jp?(date)
    defined?(HolidayJp) && HolidayJp.holiday?(date)
  end

  def find_shift_assignment(shift_day, employee)
    shift_day.assignment_for(employee)
  end

  def find_leave_request(shift_day, employee)
    shift_day.leave_request_for(employee)
  end

  def shift_header_class(shift_day)
    if shift_day.saturday?
      "shift-header-day shift-sticky-top saturday-header"
    elsif shift_day.sunday? || shift_day.holiday?
      "shift-header-day shift-sticky-top sunday-header"
    else
      "shift-header-day shift-sticky-top"
    end
  end

  def shift_cell_class(shift_day, assignment, leave_request)
    "#{shift_base_cell_class(assignment, leave_request)}#{shift_day_column_class(shift_day)}"
  end

  def shift_base_cell_class(assignment, leave_request)
    if leave_request.present?
      "shift-cell leave-request-cell"
    elsif assignment.present?
      if assignment.day_shift? || assignment.middle_shift? || assignment.night_shift?
        "shift-cell working-cell"
      else
        "shift-cell holiday-cell"
      end
    else
      "shift-cell empty-cell"
    end
  end

  def shift_day_column_class(shift_day)
    if shift_day.saturday?
      " saturday-column"
    elsif shift_day.sunday? || shift_day.holiday?
      " sunday-column"
    else
      ""
    end
  end

  def shift_work_type_select_options
    [
      ["日勤", "day_shift"],
      ["中勤", "middle_shift"],
      ["夜勤", "night_shift"],
      ["非番", "saturday_off"],
      ["週休", "sunday_off"],
      ["休暇", "holiday"],
      ["祝日休", "national_holiday"]
    ]
  end

  def work_type_options
    shift_work_type_select_options
  end

  def work_type_label(work_type)
    case work_type.to_s
    when "day_shift"
      "日勤"
    when "middle_shift"
      "中勤"
    when "night_shift"
      "夜勤"
    when "saturday_off"
      "非番"
    when "sunday_off"
      "週休"
    when "holiday"
      "休暇"
    when "national_holiday"
      "祝日休"
    else
      work_type.to_s
    end
  end

  def work_type_badge_class(work_type)
    case work_type.to_s
    when "day_shift"
      "shift-badge shift-badge-day"
    when "middle_shift"
      "shift-badge shift-badge-middle"
    when "night_shift"
      "shift-badge shift-badge-night"
    when "saturday_off", "sunday_off", "holiday", "national_holiday"
      "shift-badge shift-badge-holiday"
    else
      "shift-badge"
    end
  end

  def shift_weekday_label(target_date)
    %w[日 月 火 水 木 金 土][target_date.wday]
  end

  def toggle_form_class(form_id, open_form_id)
    classes = ["toggle-form"]
    classes << "hidden" unless form_id == open_form_id
    classes.join(" ")
  end
end