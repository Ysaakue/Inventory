class ProductsController < ApplicationController
  load_and_authorize_resource
  before_action :set_product, only: [:show,:update,:destroy,:remove_location]
  before_action :set_company, only: [:index]
  
  def index
    @products = @company.products
    if !request.query_parameters.blank? 
      if !request.query_parameters["active"].blank? && request.query_parameters["active"]
        @products = @products.where(active: true)
      else !request.query_parameters["new"].blank? && request.query_parameters["new"]
        @products = @products.where(new: true)
      end
    end
    render json: @products
  end
  
  def show
    render json: @product
  end
  
  def create
    @product = Product.new(product_params)
    if @product.location == nil
      @product.location = {}
    end
    @product.company_id = params[:company_id]
    if @product.save
      render json:{
        status: "success",
        data: @product
      }, status: :created
    else
      render json:{
        status: "error",
        message: @product.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  def update
    if @product.update(product_params)
      render json:{
        status: "success",
        data: @product
      }
    else
      render json:{
        status: "error",
        message: @product.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  def destroy
    if @product.destroy
      render json:{status: "success"}, status: 202
    else
      render json:{status: "error"}, status: 400
    end
  end

  def set_not_new
    Product.set_not_new(params[:products])
    render json:{status: "success"}, status: 202
  end

  def remove_location
    if @product.location["locations"].include? params["location"]
      @product.location["locations"].delete params["location"]
      if product.save
        render json: {
          status: "success",
          data: @product
        }
      else
        render json: {
          status: "error",
          message: @product.errors.full_messages
        }, status: :unprocessable_entity
      end
    else
      render json: {
        status: "error",
        message: ["Localização inválida"]
      }, status: 404
    end
  end

  private
  def product_params
    params.require(:product).permit(
      :active,:description,:code,:current_stock,:value,:unit_measurement
      # location: [:street, :stand, :shelf]
    )
  end

  def set_product
    @product = Product.find(params[:id])
  end

  def set_company
    @company = Company.find(params[:company_id])
  end
end
