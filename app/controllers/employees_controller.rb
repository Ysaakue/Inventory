class EmployeesController < ApplicationController
  before_action :set_employee, only: [:show,:update,:destroy]
  
  def index
    @employees = Employee.all
    render json: @employees.as_json(index: true)
  end
  
  def show
    render json: @employee
  end
  
  def create
    @employee = Employee.new(employee_params)
    if @employee.save
      render json:{
        "status": "success",
        "data": @employee
      }, status: :created
    else
      render json:{
        "status": "error",
        "data": @employee.errors
      }, status: :unprocessable_entity
    end
  end
  
  def update
    if @employee.update(employee_params)
      render json:{
        "status": "success",
        "data": @employee
      }
    else
      render json:{
        "status": "error",
        "data": @employee.errors
      }, status: :unprocessable_entity
    end
  end
  
  def destroy
    if @employee.destroy
      render json:{"status": "success"}, status: 202
    else
      render json:{"status": "error"}
    end
  end

  def identify_employee
    @employee = Employee.find_by(cpf: params[:cpf])
    render json: @employee
  end

  private
  def employee_params
    params.require(:employee).permit(:name, :cpf)
  end

  def set_employee
    @employee = Employee.find(params[:id])
  end
end
