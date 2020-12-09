class UsersController < ApplicationController
  load_and_authorize_resource
  before_action :user_params, only: [:create,:update]
  before_action :set_user, only: [:show,:update,:destroy]

  def index
    if current_user.master?
      @users = User.all
    else
      @users = current_user.users
    end
    render json: @users
  end

  def show
    render json: @user
  end

  def create
    @user = User.new(user_params)
    @user.user = current_user
    if !current_user.master?
      @user.role = Role.find_by(description: "dependent")
    end
    if @user.save
      render json: {
        status: "success",
        data: @user
      }, status: :created
    else
      render json: {
        status: "error",
        message: @user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def update
    if @user.update(user_params)
      render json: {
        status: "success",
        data: @user
      }
    else
      render json: {
        status: "error",
        message: @user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def destroy
    if @user.destroy
      render json:{status: "success"}, status: 202
    else
      render json:{status: "error"}, status: 400
    end
  end

  private
  def user_params
    params.require(:user).permit(
      :email,:password,:password_confirmation,:role_id,:name,:suspend
    )
  end

  def set_user
    @user = User.find(params[:id])
  end
end
