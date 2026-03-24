class LeaveRequestsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_shift_day

  def create
    @leave_request = @shift_day.leave_requests.new(leave_request_params)

    if @leave_request.save
      redirect_to shift_period_path(@shift_day.shift_period), notice: "希望休を登録しました。"
    else
      redirect_to shift_period_path(@shift_day.shift_period), alert: @leave_request.errors.full_messages.join(", ")
    end
  end

  def destroy
    @leave_request = @shift_day.leave_requests.find(params[:id])
    @leave_request.destroy

    redirect_to shift_period_path(@shift_day.shift_period), notice: "希望休を削除しました。"
  end

  private

  def set_shift_day
    @shift_day = ShiftDay.find(params[:shift_day_id])
  end

  def leave_request_params
    params.require(:leave_request).permit(:user_id, :note)
  end
end
