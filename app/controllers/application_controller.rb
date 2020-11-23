class ApplicationController < ActionController::API
  include DeviseTokenAuth::Concerns::SetUserByToken
  include ActionController::MimeResponds
  
  rescue_from CanCan::AccessDenied do |exception|
    @error_message = exception.message
    render json:{
      status: "error",
      "message": @error_message
    }, status: 401
  end

  def dashboard
    @employees = Employee.all
    @counts = Count.where('date >= ?', DateTime.now.years_ago(1)).order(:date)
    render json:{
      ok: "ok"
    }
  end
end
