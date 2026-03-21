class ShiftAssignmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_shift_day

  def create
    @shift_assignment = @shift_day.shift_assignments.new(shift_assignment_params)

    if @shift_assignment.save
      redirect_to shift_period_path(@shift_day.shift_period), notice: "割当を登録しました"
    else
      redirect_to shift_period_path(@shift_day.shift_period), alert: @shift_assignment.errors.full_messages.join(", ")
    end
  end

  def destroy
    @shift_assignment = @shift_day.shift_assignments.find(params[:id])
    @shift_assignment.destroy
    
    redirect_to shift_period_path(@shift_day.shift_period), notice: "割当を削除しました"
  end

  private

  def set_shift_day
    @shift_day = ShiftDay.find(params[:shift_day_id])
  end

  def shift_assignment_params
    params.require(:shift_assignment).permit(:user_id, :zone_name, :work_type)
  end
end
