class ClientsController < ApplicationController
  load_and_authorize_resource
  before_action :set_client,only:[:update,:destroy]

  def index
    @clients = Client.all
    render json: @clients
  end
  
  def show
    render json: @client
  end
  
  def create
    @client = Client.new(client_params)
    if @client.dimensions == nil
      @client.dimensions = {"streets": 0, "stand": 0,"shelfs": 0 }
    end
    if @client.save
      render json:{
        "status": "success",
        "data": @client
      }, status: :created
    else
      render json:{
        "status": "error",
        "data": @client.errors
      }, status: :unprocessable_entity
    end
  end
  
  def update
    if @client.update(client_params)
      render json:{
        "status": "success",
        "data": @client
      }
    else
      render json:{
        "status": "error",
        "data": @client.errors
      }, status: :unprocessable_entity
    end
  end
  
  def destroy
    if @client.destroy
      render json: { "status": "success"}, status: 202
    else
      render json: { "status": "error"}
    end
  end

  private
  def client_params
    params.require(:client).permit(
      :cnpj,:company_name,:fantasy_name,:state_registration,:email,
      :contact_name_telephone,:telephone_number,:contact_name_cell_phone,
      :cell_phone_number,:street_name_address,:number_address,:complement_address,
      :neighborhood_address,:postal_code_address,:state_id,:city_id,
      dimensions: [:streets, :stands, :shelfs]
    )
  end

  def set_client
    @client = Client.find(params[:id])
  end
end
