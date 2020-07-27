class CountsController < ApplicationController
  before_action :set_client, only: [:index_by_client]
  before_action :set_employee, only: [:index_by_employee]
  before_action :set_count, only: [
    :show,:update,:destroy,:fourth_count_release,:report,:report_data
  ]

  def index
    @counts = Count.all
    render json: @counts.as_json(index: true)
  end

  def index_by_client
    @counts = @client.counts
    render json: @counts.as_json(index: true)
  end

  def index_by_employee
    @counts = @employee.counts.where('status != 4 or fourth_count_employee =?', @employee.id).not_completed.not_fourth_count_pending
    render json: @counts.as_json(index: true)
  end
  
  def show
    render json: @count
  end
  
  def create
    @count = Count.new(count_params)
    @count.client_id = params[:client_id]
    if @count.save
      render json:{
        "status": "success",
        "data": @count
      }, status: :created
    else
      render json:{
        "status": "error",
        "data": @count.errors
      }, status: :unprocessable_entity
    end
  end
  
  def update
    if @count.update(count_params)
      render json:{
        "status": "success",
        "data": @count
      }
    else
      render json:{
        "status": "error",
        "data": @count.errors
      }
    end
  end
  
  def destroy
    if @count.destroy
      render json:{"status": "success"}, status: 202
    else
      render json:{"status": "error"}
    end
  end

  def submit_quantity_found
    cp = CountProduct.find_by(count_id: params[:count][:count_id], product_id: params[:count][:product_id])
    if !cp.count.completed? || cp.count.fourth_count_pending? || cp.combined_count?
      if cp.count.first_count?
        result = cp.results[0]
      elsif cp.count.second_count?
        if cp.results[0].employee_id == params[:count][:employee_id]
          employee_already_count_this_product = true
        end
        result = cp.results[1]
      elsif cp.count.third_count?
        result = cp.results[2]
      elsif cp.count.fourth_count?
        result = cp.results[3]
      end
      if result.quantity_found == -1
        result.quantity_found = params[:count][:quantity_found]
      elsif !result.count_product.product.location.blank? &&
            !result.count_product.product.location["locations"].blank? &&
            result.count_product.product.location["locations"].include?(params[:count][:location])
        product_already_count_in_this_status = true
      else
        result.quantity_found += params[:count][:quantity_found]
      end
      if employee_already_count_this_product
        render json: {
          status: "error",
          data: "Funcionário já realizou uma contagem desse produto."
        }
      elsif product_already_count_in_this_status
        render json:{
          status: "error",
          data: "Produto já contado nessa etapa."
        }
      else
        result.employee_id = params[:count][:employee_id]
        result.save!
        update_product_location(cp)
        render json:{
          status: "success",
          data: result
        }
      end
    else
      if cp.count.fourth_count_pending?
        render json:{
          status: "success",
          data: "A quarta etapa da contagem precisa ser liberada por um administrador."
        }
      elsif cp.combined_count?
        render json:{
          status: "success",
          data: "Não há divergências na contagem desse produto."
        }
      else
        render json:{
          status: "success",
          data: "A contagem já foi encerrada."
        }
      end
    end
  end

  def fourth_count_release
    @count.fourth_count_released = params[:count][:fourth_count_release]
    if @count.fourth_count_released?
      @count.employee_ids << params[:count][:employee_id]
      @count.fourth_count_employee = params[:count][:employee_id]
    else
      @count.completed!
    end
    if @count.save(validate: false)
      render json:{
        "status": "success",
        "data": @count
      }
      @count.generate_fourth_results
    else
      render json:{
        "status": "error",
        "data": @count.errors
      }
    end
  end

  def report
    pdf_html = ActionController::Base.new.render_to_string(template: 'counts/report.html.erb',:locals => {count: @count})
    pdf = WickedPdf.new.pdf_from_string(pdf_html)
    send_data pdf, filename: "relatorio_contagem_#{@count.client.fantasy_name.gsub! " ", "_"}_#{@count.date}.pdf"
  end

  def report_data
    render json:{
      id: @count.id,
      date: @count.date,
      status: @count.status,
      client: @count.client.fantasy_name,
      products: @count.counts_products,
      employees: @count.employees_to_report
    }
  end

  private
  def count_params
    params.require(:count).permit(
      :date,:status,:flags,:client_id,
      employee_ids: []
    )
  end

  def set_count
    @count = Count.find(params[:id])
  end

  def set_client
    @client = Client.find(params[:client_id])
  end

  def set_employee
    @employee = Employee.find(params[:employee_id])
  end

  def update_product_location(cp)
    if cp.product.location.blank?
      cp.product.location = {
        id: params[:count][:count_id],
        locations: [
          params[:count][:location]
        ]
      }
      cp.product.save!
    else
      if cp.product.location[:id] != params[:count][:count_id]
        cp.product.location = {
          id: params[:count][:count_id],
          locations: [
            params[:count][:location]
          ]
        }
        cp.product.save!
      else
        cp.product.location["locations"] << params[:count][:location]
        cp.product.save!
      end
    end
  end
end
