class ShiftAssignmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_shift_day
  before_action :set_shift_assignment, only: [:update, :destroy]

  def create
    @shift_assignment = @shift_day.shift_assignments.new(shift_assignment_params)

    if @shift_assignment.save
      redirect_to shift_period_path(@shift_day.shift_period), notice: "割当を登録しました。"
    else
      prepare_shift_period_show_data
      @open_form_id = "assignment-form-#{@shift_assignment.user_id}-#{@shift_day.id}"
      render "shift_periods/show", status: :unprocessable_entity
    end
  end

  def update
    if @shift_assignment.update(shift_assignment_params)
      redirect_to shift_period_path(@shift_day.shift_period), notice: "割当を更新しました。"
    else
      prepare_shift_period_show_data
      @open_form_id = "edit-assignment-form-#{@shift_assignment.id}"
      render "shift_periods/show", status: :unprocessable_entity
    end
  end

    def destroy
      @shift_assignment.destroy
      redirect_to shift_period_path(@shift_day.shift_period), notice: "割当を削除しました。"
    end

  private

  def set_shift_day
    @shift_day = ShiftDay.find(params[:shift_day_id])
  end

  def set_shift_assignment
    @shift_assignment = @shift_day.shift_assignments.find(params[:id])
  end

  def shift_assignment_params
    params.require(:shift_assignment).permit(:user_id, :work_type, :zone_id)
  end

  def prepare_shift_period_show_data
    @shift_period = @shift_day.shift_period
    @shift_days = @shift_period.shift_days
                              .includes(:leave_requests, shift_assignments: [:user, :zone])
                              .order(:target_date)
    @users = User.includes(:zones).order(:id)
  end
end