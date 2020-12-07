class RolesController < ApplicationController
  load_and_authorize_resource

  def index
    if current_user.role.description != "master"
      @roles = Role.where("description == 'dependent'")
    else
      @roles = Role.where("description != 'dependent'")
    end
    render json: @roles
  end

  def create
    @role = Role.new(role_params)
    byebug
    if @role.save
      render json:{
        status: "success",
        data: @role
      }, status: :created
    else
      render json:{
        status: "error",
        message: @role.errors
      }, status: :unprocessable_entity
    end
  end

  private
  def role_params
    params.require(:role).permit(:description,permissions: {})
  end
end
