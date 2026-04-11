module ApplicationHelper
  def shift_period_status_label(shift_period_or_status)
    status = shift_period_or_status.respond_to?(:status) ? shift_period_or_status.status : shift_period_or_status
    I18n.t("enums.shift_period.status.#{status}", default: status.to_s.humanize)
  end

  def shift_period_status_options
    ShiftPeriod.statuses.keys.map { |status| [shift_period_status_label(status), status] }
  end
end
