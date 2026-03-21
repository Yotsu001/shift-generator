class ShiftPeriodsController < ApplicationController
  before_action :authenticate_user!

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
    @shift_period = ShiftPeriod.find(params[:id])
    @users = User.order(:name)
  end

  private

  def shift_period_params
    params.require(:shift_period).permit(:name, :start_date, :end_date, :status)
  end
end
