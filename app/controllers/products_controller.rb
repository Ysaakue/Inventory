class ProductsController < ApplicationController
  before_action :set_product, only: [:show,:update,:destroy]
  before_action :set_client, only: [:index]
  
  def index
    @products = @client.products.where(active: true)
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
        "status": "success",
        "data": @product
      }, status: :created
    else
      render json:{
        "status": "error",
        "data": @product.errors
      }, status: :unprocessable_entity
    end
  end
  
  def update
    if @product.update(product_params)
      render json:{
        "status": "success",
        "data": @product
      }
    else
      render json:{
        "status": "error",
        "data": @product.errors
      }, status: :unprocessable_entity
    end
  end
  
  def destroy
    if @product.destroy
      render json:{"status": "success"}, status: 202
    else
      render json:{"status": "error"}
    end
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
