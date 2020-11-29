class ImportsController < ApplicationController
  load_and_authorize_resource
  before_action :set_company, only: [:create,:index]
  before_action :set_import, only: [:show]

  def index
    @imports = @company.imports
    render json: @imports
  end

  def show
    render json: @import
  end

  def create
    @import = Import.new
    @import.company_id = @company.id
    @import.description = "Aguardando processamento"
    @import.products = params[:products]
    if @import.save
      render json:{
        status: "success",
        data: @import
      }, status: :created
    else
      render json: {
        status: "error",
        message: @import.errors
      }, status: :unprocessable_entity
    end
  end

  private
  def set_import
    @import = Import.find(params[:id])
  end

  def set_company
    @company = Company.find(params[:company_id])
  end

  def import_params
  end
end
