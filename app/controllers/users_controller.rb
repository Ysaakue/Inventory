class UsersController < ApplicationController
  load_and_authorize_resource
  before_action :user_params, only: [:create,:update]

  def index
  end

  def show
  end

  def create
    @user = User.new(user_params)
    byebug
  end

  def update
  end

  def destroy
  end

  private
  def user_params
    params.require(:user).permit(
      :email,:password,:password_confirmation,:role,:name,permissions:{}
    )
  end
end
