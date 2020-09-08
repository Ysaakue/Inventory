class CitiesController < ApplicationController
  load_and_authorize_resource
  def index
    @cities = City.where("state_id = ?",params[:state_id])
    render json: @cities
  end
end
