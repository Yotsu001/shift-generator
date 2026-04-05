class EmployeesController < ApplicationController
  before_action :set_employee, only: %i[show edit update destroy]

  def index
    @employees = Employee.includes(:primary_zone).order(:id)
  end

  def show
  end

  def new
    @employee = Employee.new
  end

  def create
    @employee = Employee.new(employee_params)

    if @employee.save
      redirect_to employees_path, notice: 'スタッフを登録しました。'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @employee.update(employee_params)
      redirect_to employees_path, notice: 'スタッフ情報を更新しました。'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @employee.destroy
    redirect_to employees_path, notice: 'スタッフを削除しました。'
  end

  private

  def set_employee
    @employee = Employee.find(params[:id])
  end

  def employee_params
    params.require(:employee).permit(:name, :mixed_zone_preferred, :primary_zone_id)
  end
end