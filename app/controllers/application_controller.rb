class ApplicationController < ActionController::API
  include DeviseTokenAuth::Concerns::SetUserByToken
  include ActionController::MimeResponds
  
  load_and_authorize_resource :count, only: :dashboard
  
  rescue_from CanCan::AccessDenied do |exception|
    if params["action"] == "dashboard" && current_user == nil
      render json:{
        status: "error",
        "message": "Token de login expirado. Faça login novamente"
      }, status: 401
    else
      @error_message = exception.message
      render json:{
        status: "error",
        "message": @error_message
      }, status: 401
    end
  end
      
  def dashboard
    @employees = Employee
                  .joins(:counts,:results)
                  .select('employees.*,count(distinct counts.*) as counts, count(distinct results.*) as results')
                  .where('employees.user_id in (?)',[current_user.id, ((current_user.role.description == "dependent")? current_user.user.id : 0)] + current_user.user_ids)
                  .group("employees.id")
                  .order("results desc,counts desc")
                  .limit(3)
    @counts = Count.where("status = 5 and date >= ? and user_id in (?)", DateTime.now.years_ago(1),[current_user.id, ((current_user.role.description == "dependent")? current_user.user.id : 0)] + current_user.user_ids).order(:date)
    render json:{
      top_employees: @employees.as_json(index: true),
      counts: @counts.as_json(dashboard: true)
    }
  end
end
