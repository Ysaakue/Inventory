class CountsController < ApplicationController
  load_and_authorize_resource
  before_action :set_company, only: [:index_by_company]
  before_action :set_employee, only: [:index_by_employee]
  before_action :set_count, only: [
    :show,:update,:destroy,:fourth_count_release,:report_save,:report_download,
    :report_data,:pending_products,:question_results,:ignore_product,
    :divide_products,:verify_count,:set_nonconformity,:finish_count,
    :set_employees_to_third_count
  ]

  def index
    if current_user.master?
      @counts = Count.all
    else
      @counts = Count.where('user_id in (?)',[current_user.id, ((current_user.role.description == "dependent")? current_user.user.id : 0)] + current_user.user_ids).order(date: :desc, id: :desc)
    end
    render json: @counts.as_json(index: true)
  end

  def index_by_company
    @counts = @company.counts.order(date: :desc,id: :desc)
    render json: @counts.as_json(index: true)
  end

  def index_by_employee
    @counts = @employee.counts.where('status != 4 or fourth_count_employee =?', @employee.id).not_completed.not_fourth_count_pending.order(date: :desc,id: :desc)
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
    status = Count.statuses[@count.status]
    if status > 2 and status != 4
      left_count = 0
    else
      if status != 4
        status+=1
      end
      left_count = Result.where('count_product_id in (?) and results.order = ? and quantity_found = -1',@count.counts_products.ids,status).size
    end
    render json: {
      current_page: page+1,
      current_quantity_per_page: quantity,
      total_quantity: max,
      current_start: array_start,
      current_end: array_end,
      total_pages: total_pages,
      count: {
        id: @count.id,
        date: @count.date,
        goal: @count.goal,
        status: @count.status,
        report_csv_status: (file.present?? file.status : "nonexistent"),
        company: @count.company.fantasy_name,
        initial_value: @count.initial_value,
        final_value: @count.final_value,
        accuracy: @count.accuracy,
        already_counted: (@count.counts_products.where("ignore = false").size - left_count),
        left_count: left_count,
        quantity_ignored: @count.counts_products.where("ignore = true").size,
        employees: @count.employees,
        products: @count.counts_products[array_start..array_end].as_json
      }
    }
  end

  def dashboard
    file = @count.reports.find_by(content_type: "csv")
    status = Count.statuses[@count.status]
    if status > 2 and status != 4
      left_count = 0
    else
      if status != 4
        status+=1
      end
      left_count = Result.where('count_product_id in (?) and results.order = ? and quantity_found = -1',@count.counts_products.ids,status).size
    end
    render json: {
      count: {
        id: @count.id,
        date: @count.date,
        goal: @count.goal,
        status: @count.status,
        report_csv_status: (file.present?? file.status : "nonexistent"),
        company: @count.company.fantasy_name,
        initial_value: @count.initial_value,
        final_value: @count.final_value,
        accuracy: @count.accuracy,
        accuracy_by_stock: @count.accuracy_by_stock,
        already_counted: (@count.counts_products.where("ignore = false").size - left_count),
        left_count: left_count,
        quantity_ignored: @count.counts_products.where("ignore = true").size,
        employees: @count.employees,
        list_divided: ( @count.no_divided?? false : true )
      }
    }
  end

  def dashboard_table
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

    render json: {
      current_page: page+1,
      current_quantity_per_page: quantity,
      total_quantity: max,
      current_start: array_start,
      current_end: array_end,
      total_pages: total_pages,
      count: {
        products: @count.counts_products[array_start..array_end].as_json
      }
    }
  end
  
  def create
    @count = Count.new(count_params)
    @count.company_id = params[:company_id]
    if @count.products_quantity_to_count == nil
      @count.products_quantity_to_count = @count.company.products.where(active: true).size
    end
    if !params[:count][:clear_locations].blank? && params[:count][:clear_locations]
      Product.clear_location(params[:company_id])
    end
    @count.user = current_user
    if @count.save
      render json:{
        status: "success",
        data: @count
      }, status: :created
    else
      render json:{
        status: "error",
        message: @count.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  def update
    if @count.update(count_params)
      render json:{
        status: "success",
        data: @count
      }
    else
      render json:{
        status: "error",
        message: @count.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  def destroy
    if @count.destroy
      render json:{status: "success"}, status: 202
    else
      render json:{status: "error"}, status: 400
    end
  end

  def submit_quantity_found
    cp = CountProduct.find_by(count_id: params[:count][:count_id], product_id: params[:count][:product_id])
    if !cp.present?
      render json:{
        status: "error",
        message: "O produto não foi encontrado para essa contagem, verifique os dados e tente novamente."
      }, status: 400
    elsif cp.count.completed?
      render json:{
        status: "error",
        message: "A contagem já foi encerrada."
      }, status: 400
    elsif cp.count.fourth_count_pending?
      render json:{
        status: "error",
        message: "A quarta etapa da contagem precisa ser liberada por um administrador."
      }, status: 400
    elsif cp.count.calculating?
      render json:{
        status: "error",
        message: "Acontagem está sendo processada, tente novamente."
      }, status: 400
    elsif cp.combined_count?
      render json:{
        status: "error",
        message: "Não há divergências na contagem desse produto."
      }, status: 400
    else
      if  (cp.count.divided? || cp.count.redistributed?) &&
          (cp.count.first_count? || cp.count.second_count?)
        ce = CountEmployee.find_by(employee_id: params[:count][:employee_id], count_id: params[:count][:count_id])
        if ce.products["products"].index(params[:count][:product_id].to_i) == nil
          render json:{
            status: "error",
            message: "Esse produto foi designado a outro auditor."
          }, status: 400
          return
        end
      end
      if cp.count.first_count?
        result = cp.results.order(:order)[0]
      elsif cp.count.second_count?
        if cp.results.order(:order)[0].employee_id == params[:count][:employee_id]
          render json: {
            status: "error",
            message: "Você já contou este produto na etapa anterior."
          }, status: 400
          return
        end
        result = cp.results.order(:order)[1]
      elsif cp.count.third_count?
        result = cp.results.order(:order)[2]
      elsif cp.count.fourth_count?
        if cp.count.fourth_count_employee != params[:count][:employee_id]
          render json:{
            status: "error",
            message: "Outro funcionário foi designado para a quarta etapa da contagem."
          }, status: 400
          return
        end
        result = cp.results.find_by(order: 4)
      end
      if result.quantity_found == -1
        if  cp.product.location.blank? ||
            cp.product.location["step"].blank? ||
            cp.product.location["step"] != cp.count.status
          p = cp.product
          if p.location.blank?
            p.location = {}
          end
          p.location["step"] = cp.count.status
          p.location["counted_on_step"] = []
          p.save(validate: false)
        end
        result.quantity_found = params[:count][:quantity_found]
      else #result.quantity_found != -1
        if  !cp.product.location.blank? &&
            !cp.product.location["locations"].blank? &&
            cp.product.location["locations"].include?(params[:count][:location]) &&
            cp.product.location["counted_on_step"].include?(cp.product.location["locations"].index(params[:count][:location]))
          render json:{
            status: "error",
            message: "Produto já contado nessa etapa."
          }, status: 400
          return
        end
        result.quantity_found += params[:count][:quantity_found]
      end
      
      result.employee_id = params[:count][:employee_id]
      result.save!
      update_product_location(cp)
      render json:{
        status: "success",
        data: result
      }
    end
  end

  def fourth_count_release
    @count.fourth_count_released = params[:fourth_count_release]
    if @count.fourth_count_released?
      @count.employee_ids << params[:employee_id]
      @count.fourth_count_employee = params[:employee_id]
    else
      @count.status = "completed"
      Result.where('count_product_id in (?) and results.order = 4 and quantity_found = -1',@count.counts_products.ids).destroy_all
      @count.complete_products_step
    end
    if @count.save(validate: false)
      render json:{
        status: "success",
        data: @count
      }
      @count.generate_fourth_results
    else
      render json:{
        status: "error",
        message: @count.errors.full_messages
      }, status: 400
    end
  end

  def question_results
    if @count.completed?
      @count.fourth_count_released = true
      @count.employee_ids << params[:employee_id]
      @count.fourth_count_employee = params[:employee_id]
      if @count.save(validate: false)
        render json:{
          status: "success",
          data: @count
        }
        @count.question_result(params[:products_ids])
      else
        render json:{
          status: "error",
          message: @count.errors.full_messages
        }, status: 400
      end
    else
      render json:{
        status: "error",
        message: ["Para realizar a auditoria programada de uma contagem é preciso que ela tenha sido concluida."]
      }, status: 400
    end
  end

  def report_pdf
    pdf_html = ActionController::Base.new.render_to_string(template: 'counts/report.html.erb',:locals => {count: @count})
    pdf = WickedPdf.new.pdf_from_string(pdf_html)
    send_data pdf, filename: "relatorio_contagem_#{@count.company.fantasy_name.gsub! " ", "_"}_#{@count.date}.pdf"
  end

  def report_save
    @count.generate_report(params[:file_format])
    render json: {
      status: "success",
      data: "O arquivo está sendo gerado."
    }
  end
  
  def report_download
    if params[:format] == "xlsx"
      send_data(
        @count.to_xlsx.to_stream.read,
        type: "xlsx",
        filename: "relatorio_contagem_#{(!(@count.company.fantasy_name.include? " ") == false)? (@count.company.fantasy_name.gsub! " ", "_") : (@count.company.fantasy_name)}_#{@count.date.strftime("%d-%m-%Y")}.xlsx"
      )
    else
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
          send_data pdf, filename: "relatorio_contagem_#{@count.company.fantasy_name.gsub! " ", "_"}_#{@count.date}.pdf"
        end
      end
    end
  end

  def report_data
    render json:{
      id: @count.id,
      date: @count.date,
      status: @count.status,
      company: @count.company.fantasy_name,
      products: @count.counts_products,
      employees: @count.employees_to_report
    }
  end

  def pending_products
    status = Count.statuses[@count.status]
    if status < 3
      status+=1
    end
    if (@count.divided? || @count.redistributed?)  && !@count.fourth_count?
      products = CountProduct.joins("inner join results on results.count_product_id = count_products.id and results.order = #{status} and count_products.count_id = #{@count.id} and count_products.product_id in (#{@count.counts_employees.find_by(employee_id: params[:employee_id]).products["products"].join(',')})")
    else
      products = CountProduct.joins("inner join results on results.count_product_id = count_products.id and results.order = #{status} and count_products.count_id = #{@count.id}")
    end
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
    @cp.combined_count = true
    if @cp.save
      @cp.reset_results
      @count.delay.calculate_initial_value
      @count.delay.calculate_final_value
      if !@count.first_count? && !@count.calculating?
        @count.verify_count
      end
      render json:{
        status: "success",
        data: @cp.as_json
      }
    else
      render json:{
        status: "error",
        message: @cp.errors.full_messages
      }, status: 400
    end
  end

  def divide_products
    if @count.no_divided?
      @count.divide_products_lists
      render json:{
        status: "success"
      }
    else
      render json:{
        status: "error",
        message: ["As listas já foram distribuidas para essa contagem."]
      }, status: 400
    end
  end

  def set_employees_to_third_count
    @count.delegate_employee_to_third_count(params[:employee_ids])
    render json: { status: "success" }
  end

  def products_simplified
    render json:{
      products: @count.counts_products.where("ignore = false and percentage_result != 100").as_json(fake_product: true)
    }
  end

  def verify_count
    @count.verify_count
    render json:{
      status: "success"
    }
  end

  def set_nonconformity
    @cp = CountProduct.find_by(product_id: params[:product_id],count_id: @count.id)
    @cp.ignore = true
    @cp.nonconformity = params["nonconformity"]
    @cp.combined_count = true
    if @cp.save
      @cp.reset_results
      @count.delay.calculate_initial_value
      @count.delay.calculate_final_value
      if !@count.first_count? && !@count.calculating?
        @count.verify_count
      end
      render json:{
        status: "success",
        data: @cp.as_json
      }
    else
      render json:{
        status: "errors",
        message: @cp.errors.full_messages
      }, status: 400
    end
  end

  def merge_reports
    cols = [
      "DATA","EMPRESA","COD","MATERIAL","UND","VLR UNIT","VLRT TOTAL","SALDO INICIAL",
      "CONT 1","CONT 2","CONT 3","CONT 4","SALDO FINAL","RESULTADO %","RUA","ESTANTE",
      "PRATELEIRA","PALLET","VLR TOTAL FINAL","RESULTADO VLR %", "JUSTIFICATIVA"
    ]
    counts = Count.where('id in (?)',params[:ids])
    merge = CSV.generate(headers: true) do |csv|
      csv << cols
      company_date = []
      accuracy = []
      initial_value = []
      final_value =[]
      average_accuracy = 0
      counts.each do |count|
        company_date << "#{count.company.fantasy_name} - #{count.date}"
        accuracy << (count.accuracy.gsub! '.',',')
        average_accuracy += count.accuracy
        initial_value << (count.initial_value.gsub! '.',',')
        final_value << (count.final_value.gsub! '.',',')
        row = []
        row << count.date #DATA
        count.counts_products.each do |cp|
          row << count.company.fantasy_name #EMPRESA
          row << cp.product.code #COD
          row << cp.product.description #MATERIAL
          row << cp.product.unit_measurement #UND
          row << (cp.product.value.gsub! '.',',') #VLR UNIT
          row << (cp.total_value.gsub! '.',',') #VLRT TOTAL
          row << cp.product.current_stock #SALDO INICIAL
          row << ((cp.results.find_by(order: 1).blank? || cp.results.find_by(order: 1).quantity_found < 0)? '-' : cp.results.find_by(order: 1).quantity_found) #CONT 1
          row << ((cp.results.find_by(order: 2).blank? || cp.results.find_by(order: 2).quantity_found < 0)? '-' : cp.results.find_by(order: 2).quantity_found) #CONT 2
          row << ((cp.results.find_by(order: 3).blank? || cp.results.find_by(order: 3).quantity_found < 0)? '-' : cp.results.find_by(order: 3).quantity_found) #CONT 3
          row << ((cp.results.find_by(order: 4).blank? || cp.results.find_by(order: 4).quantity_found < 0)? '-' : cp.results.find_by(order: 4).quantity_found) #CONT 4
          row << ((cp.results.order(:order).last.blank? || cp.results.order(:order).last.quantity_found < 0)? '-' : cp.results.order(:order).last.quantity_found) #SALDO FINAL
          row << cp.percentage_result #RESULTADO %
          streets = []
          stands  = []
          shelfs  = []
          pallets  = []
          if !cp.product.location.blank? && !cp.product.location["locations"].blank?
            cp.product.location["locations"].each do |location|
              if location.keys.include? "pallet"
                pallets << location["pallet"]
              else
                streets << location["street"]
                stands  << location["stand"]
                shelfs  << location["shelf"]
              end
            end
          end
          row << streets.join(',') #RUA
          row << stands.join(',') #ESTANTE
          row << shelfs.join(',') #PRATELEIRA
          row << pallets.join(',') #PALLETS
          row << (cp.final_total_value.gsub! '.',',') #VLR TOTAL FINAL
          row << cp.percentage_result_value #RESULTADO VLR %
          row << (cp.ignore?? ((cp.justification != nil)? cp.justification : cp.nonconformity ) : '') #JUSTIFICATIVA
          csv << row
          row = [""]
        end
      end
      csv << []
      csv << ["Empresa/Data"] + company_date
      csv << ["Valor Total"] + initial_value
      csv << ["Valor Resultado"] + final_value
      csv << ["Acuracidade"] + accuracy
      csv << []
      csv << ["Acuracidade média:", ((average_accuracy / counts.size).gsub! '.',',')] 
    end
    send_data(
      merge,
      type: "csv",
      filename: "mesclagem_relatorios.csv"
    )
  end

  def finish_count
    if @count.completed!
      render json:{
        status: "success",
        data: @count.as_json(dashboard: true)
      }
    else
      render json:{
        status: "error",
        message: @count.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private
  def count_params
    params.require(:count).permit(
      :date,:company_id,:products_quantity_to_count,:goal,
      employee_ids: []
    )
  end

  def set_count
    @count = Count.find(params[:id])
  end

  def set_company
    @company = Company.find(params[:company_id])
  end

  def set_employee
    @employee = Employee.find(params[:employee_id])
  end

  def update_product_location(cp)
    product = cp.product
    if product.location.blank?
      product.location = {
        id: params[:count][:count_id],
        locations: [
          params[:count][:location]
        ]
      }
    else
      if product.location["id"] != params[:count][:count_id]
        product.location["id"] = params[:count][:count_id]
        # product.location["locations"] = []
        # product.location["locations"] << params[:count][:location]
        # product.location["counted_on_step"] << product.location["locations"].index(params[:count][:location])
      end
      if product.location["locations"].blank?
        product.location["locations"] = []
      end
      if !product.location["locations"].include?(params[:count][:location])
        product.location["locations"] << params[:count][:location]
        product.location["counted_on_step"] << product.location["locations"].index(params[:count][:location])
      elsif !product.location["locations"].blank? &&
            product.location["locations"].include?(params[:count][:location])
        product.location["counted_on_step"] << product.location["locations"].index(params[:count][:location])
      end
    end
    product.save(validate: false)
  end
end
