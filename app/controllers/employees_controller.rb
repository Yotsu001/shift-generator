class EmployeesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_employee, only: %i[show edit update destroy]

  def index
    @employees = current_user.employees.includes(:primary_zone, :zones).order(:display_order, :id)
  end

  def show
  end

  def new
    @employee = current_user.employees.new
  end

  def create
    @employee = current_user.employees.new(employee_params)

    if @employee.save
      redirect_to employees_path, notice: 'スタッフを登録しました。'
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @employee.update(employee_params)
      redirect_to employees_path, notice: 'スタッフ情報を更新しました。'
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @employee.destroy
    redirect_to employees_path, notice: 'スタッフを削除しました。'
  end

  private

  def set_employee
    @employee = current_user.employees.find(params[:id])
  end

  def employee_params
    params.require(:employee).permit(:name, :mixed_zone_preferred, :must_staff, :primary_zone_id, :weekend_work_disabled, zone_ids: [])
  end
end
