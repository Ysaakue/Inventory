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
    @employees = Employee
                  .joins(:counts,:results)
                  .select('employees.*,count(distinct counts.*) as counts, count(distinct results.*) as results')
                  .group("employees.id")
                  .order("results desc,counts desc")
                  .limit(3)
    @counts = Count.where("date >= ?", DateTime.now.years_ago(1)).order(:date)
    render json:{
      top_employees: @employees.as_json(index: true),
      counts: @counts.as_json(dashboard: true)
    }
  end
end
