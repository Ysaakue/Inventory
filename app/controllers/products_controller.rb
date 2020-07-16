class ProductsController < ApplicationController
  before_action :set_product, only: [:show,:update,:destroy]
  before_action :set_client, only: [:index]
  
  def index
    @products = @client.products
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

  def import
    total = 0
    saved = 0
    params[:products].each do |product|
      total+=1
      product = Product.new(
        description: product[:description],
        code: product[:code],
        current_stock: product[:current_stock],
        value: product[:value],
        unit_measurement: product[:unit_measurement],
        client_id: params[:client_id]
      )
      if product.location == nil
        product.location = []
      end
      if product.save
        saved+=1
      end
    end
    render json:{
      "status": "success",
      "data": "Foram registrados #{saved} produtos de um total de #{total}"
    }
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
