class ShiftPeriodsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_shift_period, only: [:show, :generate, :clear_assignments]

  def index
    @shift_periods = ShiftPeriod.order(start_date: :desc)
  end

  def new
    @shift_period = ShiftPeriod.new
  end

  def create
    @shift_period = ShiftPeriod.new(shift_period_params)
    if @shift_period.save
      redirect_to @shift_period, notice: "シフト期間を作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    prepare_show_resources
  end

  def generate
    ShiftGeneration::SimpleGenerator.new(@shift_period).call
    redirect_to @shift_period, notice: "平日の自動割当を生成しました"
  rescue StandardError => e
    Rails.logger.error e.full_message
    redirect_to @shift_period, alert: "自動生成に失敗しました"
  end

  def clear_assignments
    ShiftAssignment.joins(:shift_day)
                   .where(shift_days: { shift_period_id: @shift_period.id })
                   .delete_all

    redirect_to shift_period_path(@shift_period), notice: "割当を全削除しました"
  end

  private

  def set_shift_period
    @shift_period = ShiftPeriod.includes(shift_days: [:shift_assignments, :leave_requests]).find(params[:id])
  end

  def shift_period_params
    params.require(:shift_period).permit(:name, :start_date, :end_date, :status)
  end

  def prepare_show_resources
    @employees = Employee.active_ordered
    @shift_days = @shift_period.shift_days.order(:target_date)
    @shift_assignments = @shift_period.shift_assignments.includes(:employee, :zone, :shift_day)
    @leave_requests = @shift_period.leave_requests.includes(:employee, :shift_day)
    @zones = Zone.all
  end
end