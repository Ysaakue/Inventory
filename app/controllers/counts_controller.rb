class CountsController < ApplicationController
  load_and_authorize_resource
  before_action :set_client, only: [:index_by_client]
  before_action :set_employee, only: [:index_by_employee]
  before_action :set_count, only: [
    :show,:update,:destroy,:fourth_count_release,:report_save,:report_download,:report_data,
    :pending_products,:question_results, :ignore_product
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
    page = 0
    quantity = 50
    if !request.query_parameters.blank? && !request.query_parameters["quant"].blank?
      quantity = request.query_parameters["quant"].to_i
    end
    if !request.query_parameters.blank? && !request.query_parameters["pag"].blank?
      page = request.query_parameters["pag"].to_i - 1
    end
    max = @count.counts_products.size
    if max % quantity > 0
      total_pages = (max / quantity) + 1
    else
      total_pages = (max / quantity)
    end
    array_start = 0
    array_end = max-1
    if total_pages > 1 && page <= total_pages
      array_start = page * quantity
      if (array_start + quantity - 1) < (max-1)
        array_end = array_start + quantity - 1
      end
    end

    file = @count.reports.find_by(content_type: "csv")
    left_count = Result.where('count_product_id in (?) and results.order = ? and quantity_found = -1',@count.counts_products.ids,Count.statuses[@count.status]).size
    render json: {
      current_page: page,
      current_quantity_per_page: quantity,
      total_quantity: max,
      current_start: array_start,
      current_end: array_end,
      total_pages: total_pages,
      count: {
        id: @count.id,
        date: @count.date,
        status: @count.status,
        report_csv_status: (file.present?? file.status : "nonexistent"),
        client: @count.client.fantasy_name,
        initial_value: @count.initial_value,
        final_value: @count.final_value,
        accuracy: @count.accuracy,
        already_counted: max-left_count,
        left_count: left_count,
        employees: @count.employees,
        products: @count.counts_products[array_start..array_end].as_json
      }
    }
  end
  
  def create
    @count = Count.new(count_params)
    @count.client_id = params[:client_id]
    if @count.products_quantity_to_count == nil
      @count.products_quantity_to_count = @count.client.products.where(active: true).size
    end
    if !params[:count][:clear_locations].blank? && params[:count][:clear_locations]
      Product.clear_location(params[:client_id])
    end
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
    if !cp.present?
      render json:{
        status: "error",
        data: "O produto não foi encontrado para essa contagem, verifique os dados e tente novamente."
      }
    elsif cp.count.completed?
      render json:{
        status: "error",
        data: "A contagem já foi encerrada."
      }
    elsif cp.count.fourth_count_pending?
      render json:{
          status: "error",
          data: "A quarta etapa da contagem precisa ser liberada por um administrador."
        }
    elsif cp.combined_count?
      render json:{
        status: "error",
        data: "Não há divergências na contagem desse produto."
      }
    else
      if cp.count.first_count?
        result = cp.results.order(:order)[0]
      elsif cp.count.second_count?
        if cp.results.order(:order)[0].employee_id == params[:count][:employee_id]
          employee_already_count_this_product = true
        end
        result = cp.results.order(:order)[1]
      elsif cp.count.third_count?
        result = cp.results.order(:order)[2]
      elsif cp.count.fourth_count?
        if cp.count.fourth_count_employee != params[:count][:employee_id]
          unassigned_employee = true
        end
        result = cp.results.order(:order)[3]
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
      elsif unassigned_employee
        render json:{
          status: "error",
          data: "Outro funcionário foi designado para a quarta etapa da contagem."
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
    end
  end

  def fourth_count_release
    @count.fourth_count_released = params[:fourth_count_release]
    if @count.fourth_count_released?
      @count.employee_ids << params[:employee_id]
      @count.fourth_count_employee = params[:employee_id]
    else
      @count.status = "completed"
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

  def question_results
    @count.fourth_count_released = true
    @count.employee_ids << params[:employee_id]
    @count.fourth_count_employee = params[:employee_id]
    if @count.save(validate: false)
      render json:{
        "status": "success",
        "data": @count
      }
      @count.question_result(params[:products_ids])
    else
      render json:{
        "status": "error",
        "data": @count.errors
      }
    end
  end

  def report_pdf
    pdf_html = ActionController::Base.new.render_to_string(template: 'counts/report.html.erb',:locals => {count: @count})
    pdf = WickedPdf.new.pdf_from_string(pdf_html)
    send_data pdf, filename: "relatorio_contagem_#{@count.client.fantasy_name.gsub! " ", "_"}_#{@count.date}.pdf"
  end

  def report_save
    @count.generate_report(params[:file_format])
    render json: {
      "status": "sucess",
      "data": "O arquivo está sendo gerado."
    }
  end
  
  def report_download
    respond_to do |format|
      format.csv do
        @report = @count.reports.find_by(content_type: "csv")
        send_data(
          @report.file_contents,
          type: @report.content_type,
          filename: @report.filename
        )
      end
      format.pdf do
        pdf_html = ActionController::Base.new.render_to_string(template: 'counts/report.html.erb',:locals => {count: @count})
        pdf = WickedPdf.new.pdf_from_string(pdf_html)
        send_data pdf, filename: "relatorio_contagem_#{@count.client.fantasy_name.gsub! " ", "_"}_#{@count.date}.pdf"
      end
    end
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

  def pending_products
    products = CountProduct.joins("inner join results on results.quantity_found = -1 and results.count_product_id = count_products.id and results.order = #{Count.statuses[@count.status]} and count_products.count_id = #{@count.id}")
    render json: {
      count: {
        status: @count.status,
        products: products.as_json(simple: true)
      }
    }
  end

  def ignore_product
    @cp = CountProduct.find_by(product_id: params[:product_id],count_id: @count.id)
    @cp.ignore = true
    @cp.justification = params[:justification]
    byebug
    if @cp.save
      @cp.reset_results
      @count.delay.calculate_initial_value
      @count.delay.calculate_final_value
      render json:{
        "status": "success",
        "data": @cp.as_json
      }
    else
      render json:{
        "status": "errors",
        "data": @cp.errors
      }
    end
  end

  private
  def count_params
    params.require(:count).permit(
      :date,:status,:client_id,:products_quantity_to_count,
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
    else
      if cp.product.location["id"] != params[:count][:count_id]
        cp.product.location = {
          id: params[:count][:count_id],
          locations: [
            params[:count][:location]
          ]
        }
      elsif !cp.product.location["locations"].include? params[:count][:location]
        cp.product.location["locations"] << params[:count][:location]
      end
    end
    cp.product.save!
  end
end
