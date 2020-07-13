class ApplicationController < ActionController::API
  include DeviseTokenAuth::Concerns::SetUserByToken

  rescue_from CanCan::AccessDenied do |exception|
    @error_message = exception.message
    render json:{
      status: "error",
      "data": @error_message
    }, status: 401
  end
end
