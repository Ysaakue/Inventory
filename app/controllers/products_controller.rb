class ProductsController < ApplicationController
  load_and_authorize_resource
  before_action :set_product, only: [:show,:update,:destroy]
  before_action :set_client, only: [:index]
  
  def index
    @products = @client.products.where(active: true)
    if !request.query_parameters.blank? && !request.query_parameters["active"].blank? && !request.query_parameters["active"]
      @products = @client.products
    end
    if !request.query_parameters.blank? && !request.query_parameters["new"].blank? && request.query_parameters["active"]
      @products = @products.where(new: true)
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
    @product.client_id = params[:client_id]
    if @product.save
      render json:{
        status: "success",
        data: @product
      }, status: :created
    else
      render json:{
        status: "error",
        message: @product.errors
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
        message: @product.errors
      }, status: :unprocessable_entity
    end
  end
  
  def destroy
    if @product.destroy
      render json:{status: "success"}, status: 202
    else
      render json:{status: "error"}
    end
  end

  def set_not_new
    Product.set_not_new(params[:products])
    render json:{status: "success"}, status: 202
  end

  private
  def product_params
    params.require(:product).permit(
      :description,:code,:current_stock,:value,:client_id,:unit_measurement,
      location: [:street, :stand, :shelf]
    )
  end

  def set_product
    @product = Product.find(params[:id])
  end

  def set_client
    @client = Client.find(params[:client_id])
  end
end
