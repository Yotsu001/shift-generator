module ApplicationHelper
  SHIFT_PERIOD_STATUS_LABELS = {
    "draft" => "案",
    "locked" => "確定"
  }.freeze

  def shift_period_status_label(shift_period_or_status)
    status = shift_period_or_status.respond_to?(:status) ? shift_period_or_status.status : shift_period_or_status
    SHIFT_PERIOD_STATUS_LABELS[status.to_s] || I18n.t("enums.shift_period.status.#{status}", default: status.to_s)
  end

  def shift_period_status_options
    ShiftPeriod.statuses.keys.map { |status| [shift_period_status_label(status), status] }
  end
end
