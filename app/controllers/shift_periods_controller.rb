class ShiftPeriodsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_shift_period, only: [:show, :generate]

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
    @shift_days = @shift_period.shift_days.order(:target_date)
    @users = User.includes(:zones).order(:id)
  end

  def generate
    ShiftGeneration::SimpleGenerator.new(@shift_period).call
    redirect_to @shift_period, notice: "平日の自動割当を生成しました"
  rescue StandardError => e
    Rails.logger.error e.full_message
    redirect_to @shift_period, alert: "自動生成に失敗しました"
  end

  private

  def set_shift_period
    @shift_period = ShiftPeriod.includes(shift_days: [:shift_assignments, :leave_requests]).find(params[:id])
  end

  def shift_period_params
    params.require(:shift_period).permit(:name, :start_date, :end_date, :status)
  end
end