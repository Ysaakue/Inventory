class CountsController < ApplicationController
  before_action :set_client, only: [:index]
  before_action :set_employee, only: [:index_by_employee]
  before_action :set_count, only: [:show,:update,:destroy]

  def index
    @counts = @client.counts
    render json: @counts
  end

  def index_by_employee
    @counts = @employee.counts.not_completed
    render json: @counts
  end
  
  def show
    render json: @count
  end
  
  def create
    @count = Count.new(count_params)
    @count.client_id = params[:client_id]
    if @count.flags == nil
      @count.flags = {}
    end
    if @count.save
      render json:{
        "status": "success",
        "data": @count
      }, status: :created
    else
      render json:{
        "status": "error",
        "data": @count.errors
      }, status: :unprocessable_entity
    end
  end
  
  def update
    if @count.update(count_params)
      render json:{
        "status": "success",
        "data": @count
      }
    else
      render json:{
        "status": "error",
        "data": @count.errors
      }
    end
  end
  
  def destroy
    if @count.destroy
      render json:{"status": "success"}
    else
      render json:{"status": "error"}
    end
  end

  private
  def count_params
    params.require(:count).permit(
      :date,:status,:flags,:client_id,
      employee_ids: []
    )
  end

  def set_count
    @count = Count.find(params[:id])
  end

  def set_client
    @client = Client.find(params[:client_id])
  end

  def set_employee
    @employee = Employee.find(params[:employee_id])
  end
end
