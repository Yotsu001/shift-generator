class ShiftPeriodsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_shift_period, only: [:show, :edit, :update, :destroy, :generate, :clear_assignments]
  before_action :prevent_locked_shift_period_actions, only: [:generate, :clear_assignments]

  def index
    @shift_periods = current_user.shift_periods.order(start_date: :desc)
  end

  def new
    @shift_period = current_user.shift_periods.new
  end

  def create
    @shift_period = current_user.shift_periods.new(shift_period_params)
    if @shift_period.save
      redirect_to @shift_period, notice: "シフト期間を作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    date_range_changed = shift_period_date_range_changed?

    ShiftPeriod.transaction do
      if @shift_period.update(shift_period_params)
        @shift_period.rebuild_shift_days! if date_range_changed
      else
        raise ActiveRecord::Rollback
      end
    end

    if @shift_period.errors.any?
      render :edit, status: :unprocessable_entity
    else
      notice = if date_range_changed
                 "シフト期間を更新しました。日付範囲の変更に伴い、シフト表を再作成しました"
               else
                 "シフト期間を更新しました"
               end
      redirect_to shift_periods_path, notice: notice
    end
  end

  def destroy
    @shift_period.destroy!
    redirect_to shift_periods_path, notice: "シフト期間を削除しました"
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
    @shift_period = current_user.shift_periods.includes(shift_days: [:shift_assignments, :leave_requests]).find(params[:id])
  end

  def shift_period_params
    params.require(:shift_period).permit(:name, :start_date, :end_date, :status)
  end

  def shift_period_date_range_changed?
    @shift_period.start_date != parsed_shift_period_date(:start_date) ||
      @shift_period.end_date != parsed_shift_period_date(:end_date)
  end

  def parsed_shift_period_date(key)
    value = params.dig(:shift_period, key)
    value.present? ? Date.parse(value) : nil
  rescue ArgumentError
    nil
  end

  def prevent_locked_shift_period_actions
    return unless @shift_period.locked?

    redirect_to shift_period_path(@shift_period), alert: "確定済みのシフト期間ではこの操作を実行できません"
  end

  def prepare_show_resources
    @employees = current_user.employees.active_ordered
    @shift_days = @shift_period.shift_days.order(:target_date)
    @shift_assignments = @shift_period.shift_assignments.includes(:employee, :zone, :shift_day)
    @leave_requests = @shift_period.leave_requests.includes(:employee, :shift_day)
    @zones = Zone.all
  end
end