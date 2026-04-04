module ShiftPeriodsHelper
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
      if assignment.day_shift? || assignment.night_shift?
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
      ["夜勤", "night_shift"],
      ["非番", "off_duty"],
      ["休日", "holiday"]
    ]
  end

  def shift_weekday_label(target_date)
    %w[日 月 火 水 木 金 土][target_date.wday]
  end
end