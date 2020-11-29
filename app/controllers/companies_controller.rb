class CompaniesController < ApplicationController
  load_and_authorize_resource
  before_action :set_company,only:[:update,:destroy,:grant_access,:suspend_access]

  def index
    @companies = Company.all
    render json: @companies
  end
  
  def show
    render json: @company
  end
  
  def create
    @company = Company.new(company_params)
    if @company.dimensions == nil
      @company.dimensions = {"streets": 0, "stands": 0,"shelfs": 0,"pallets": 0 }
    end
    if @company.save
      render json:{
        status: "success",
        data: @company
      }, status: :created
    else
      render json:{
        status: "error",
        message: @company.errors
      }, status: :unprocessable_entity
    end
  end
  
  def update
    if @company.update(company_params)
      render json:{
        status: "success",
        data: @company
      }
    else
      render json:{
        status: "error",
        message: @company.errors
      }, status: :unprocessable_entity
    end
  end
  
  def destroy
    if @company.destroy
      render json: { status: "success"}, status: 202
    else
      render json: { status: "error"}
    end
  end

  private
  def company_params
    params.require(:company).permit(
      :cnpj,:company_name,:fantasy_name,:state_registration,:email,
      :contact_name_telephone,:telephone_number,:contact_name_cell_phone,
      :cell_phone_number,:street_name_address,:number_address,:complement_address,
      :neighborhood_address,:postal_code_address,:state_id,:city_id,
      dimensions: [:streets, :stands, :shelfs]
    )
  end

  def set_company
    @company = Company.find(params[:id])
  end
end
