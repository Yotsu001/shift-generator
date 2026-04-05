class LeaveRequestsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_shift_day
  before_action :set_leave_request, only: [:update, :destroy]

  def create
    @leave_request = @shift_day.leave_requests.new(leave_request_params)

    if @leave_request.save
      redirect_to shift_period_path(@shift_day.shift_period), notice: "希望休を登録しました。"
    else
      prepare_shift_period_show_data
      @open_form_id = "leave-form-#{@leave_request.employee_id}-#{@shift_day.id}"
      render "shift_periods/show", status: :unprocessable_entity
    end
  end

  def update
    if @leave_request.update(leave_request_params)
      redirect_to shift_period_path(@shift_day.shift_period), notice: "希望休を更新しました。"
    else
      prepare_shift_period_show_data
      @open_form_id = "edit-leave-form-#{@leave_request.id}"
      render "shift_periods/show", status: :unprocessable_entity
    end
  end

  def destroy
    @leave_request.destroy
    redirect_to shift_period_path(@shift_day.shift_period), notice: "希望休を削除しました。"
  end

  private

  def set_shift_day
    @shift_day = ShiftDay.find(params[:shift_day_id])
  end

  def set_leave_request
    @leave_request = @shift_day.leave_requests.find(params[:id])
  end

  def leave_request_params
    params.require(:leave_request).permit(:employee_id, :note)
  end

  def prepare_shift_period_show_data
    @shift_period = @shift_day.shift_period
    @employees = Employee.active_ordered
    @shift_days = @shift_period.shift_days.order(:target_date)
    @shift_assignments = @shift_period.shift_assignments.includes(:employee, :zone, :shift_day)
    @leave_requests = @shift_period.leave_requests.includes(:employee, :shift_day)
    @zones = Zone.all
  end
end