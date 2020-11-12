class ClientsController < ApplicationController
  load_and_authorize_resource
  before_action :set_client,only:[:update,:destroy,:grant_access,:suspend_access]

  def index
    if current_user.client_id.blank?
      @clients = Client.all
    else
      @clients = Client.where('id = ?',current_user.client.id)
    end
    render json: @clients
  end
  
  def show
    render json: @client
  end
  
  def create
    @client = Client.new(client_params)
    if @client.dimensions == nil
      @client.dimensions = {"streets": 0, "stands": 0,"shelfs": 0,"pallets": 0 }
    end
    if @client.save
      render json:{
        status: "success",
        message: @client
      }, status: :created
    else
      render json:{
        status: "error",
        message: @client.errors
      }, status: :unprocessable_entity
    end
  end
  
  def update
    if @client.update(client_params)
      render json:{
        status: "success",
        message: @client
      }
    else
      render json:{
        status: "error",
        message: @client.errors
      }, status: :unprocessable_entity
    end
  end
  
  def destroy
    if @client.destroy
      render json: { status: "success"}, status: 202
    else
      render json: { status: "error"}
    end
  end

  def suspend_access
    @user = @client.user
      @user.suspended = true
      if @user.save
        render json:{
          status: "success",
          message: @user
        }
      else
        render json:{
          status: "error",
          message: @user.errors
        }
      end
  end

  def grant_access
    if @client.user.present?
      @user = @client.user
      @user.suspended = false
      if @user.save
        render json:{
          status: "success",
          message: @user
        }
      else
        render json:{
          status: "error",
          message: @user.errors
        }
      end
    else
      @user = User.new
      @user.email = @client.email
      @user.password = @client.cnpj.gsub('.','')[0..5]
      @user.client = @client
      if @user.save
        render json:{
          status: "success",
          message: @user
        }, status: :created
      else
        render json:{
          status: "error",
          message: @user.errors
        },status: :unprocessable_entity
      end
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
