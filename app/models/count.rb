class Count < ApplicationRecord
  belongs_to :company
  belongs_to :user
  has_many :counts_employees, class_name: "CountEmployee"
  has_many :employees, through: :counts_employees
  has_many :counts_products, class_name: "CountProduct"
  has_many :products, through: :counts_products
  has_many :reports
  
  after_create :prepare_count

  validate :date_not_retrograde
  validate :can_create, on: :create
  validate :verify_if_exist_incomplete, on: :create

  enum status: [
    :first_count,           #0 -> 1
    :second_count,          #1 -> 2
    :third_count,           #2 -> 3
    :fourth_count_pending,  #3
    :fourth_count,          #4 -> 4
    :completed,             #5
    :calculating            #6
  ]

  enum filter: [
    :random,                #0
    :value,                 #1
    :turnover               #2
  ]

  enum divide_status: [
    :no_divided,
    :dividing,
    :divided,
    :redistributed
  ]

  def date_not_retrograde
    if date == nil || date < Date.today
      errors.add(:date, "A data não pode ser retrograda")
    end
  end

  def as_json options={}
    if options 
      index = if options.key?(:index)
        options[:index]
      end
      dashboard = if options.key?(:dashboard)
        options[:dashboard]
      end
    end
    if index
      {
        id: id,
        date: date,
        status: status,
        company: company.fantasy_name
      }
    elsif dashboard
      {
        id: id,
        date: date,
        company: company.fantasy_name,
        accuracy: accuracy,
        products_quantity: products.count
      }
    else
      {
        id: id,
        date: date,
        goal: goal,
        status: status,
        company: company.fantasy_name,
        employees: employees,
        products: counts_products
      }
    end
  end

  def prepare_count
    if !self.calculating?
      self.calculating!
      temp_products = company.products.where(active: true)
      if products_quantity_to_count < temp_products.size
        if value?
          temp_products =  temp_products.where('value >= ?', self.minimum_value)
                                        .order(value: :desc)
                                        .limit(products_quantity_to_count)
        elsif turnover?
          temp_products =  temp_products.select('*,(products.output*100/products.input) as giro')
                                        .where('products.input is not null').order('giro desc')
                                        .limit(products_quantity_to_count)
        else
          temp_products = temp_products.shuffle[0..products_quantity_to_count-1]
        end
      end
      initial_value = 0
      temp_products.each do |product|
        if !product.location.blank? && !product.location["step"].blank?
          product.location.delete("step")
        end
        if !product.location.blank? && !product.location["counted_on_step"].blank?
          product.location.delete("counted_on_step")
        end
        product.save
        total_value = product.value * product.current_stock
        cp = CountProduct.new(
          product_id: product.id,
          count_id: id,
          combined_count: false,
          total_value: total_value
        )
        cp.save(validate: false)
        self.initial_value += cp.total_value
        self.initial_stock += product.current_stock
        Result.new(
          count_product_id: cp.id,
          order: 1,
        ).save(validate: false)
      end
      self.first_count!
    end
  end

  def verify_count
    if !self.calculating?
      status_before = self.status
      self.calculating!
      one = 0
      two = 0
      three = 0
      four = 0
      status = ""
      self.counts_products.where("ignore = false").each do |cp|
        if !cp.combined_count?
          if cp.results.size == 1
            one+=1
          elsif cp.results.size == 2 &&
                cp.results.order(:order).last.quantity_found == -1 || 
                (
                  !cp.product.location["locations"].blank? &&
                  cp.product.location["locations"].size > 1 &&
                  !cp.product.location["counted_on_step"].blank? &&
                  cp.product.location["counted_on_step"].size != cp.product.location["locations"].size
                )
            two+=1
          elsif cp.results.size == 3 &&
                cp.results.order(:order).last.quantity_found == -1 || 
                (
                  !cp.product.location["locations"].blank? &&
                  cp.product.location["locations"].size > 1 &&
                  !cp.product.location["counted_on_step"].blank? &&
                  cp.product.location["counted_on_step"].size != cp.product.location["locations"].size
                )
            three+=1
          elsif cp.results.order(:order).last.quantity_found == -1 ||
                (
                  !cp.product.location["locations"].blank? &&
                  cp.product.location["locations"].size > 1 &&
                  !cp.product.location["counted_on_step"].blank? &&
                  cp.product.location["counted_on_step"].size != cp.product.location["locations"].size
                )
            four+=1
          end
        end
      end
      if status_before == "first_count" && one == 0
        self.second_count!
        status = self.status
        if self.divided?
          self.redistribute_products_lists
        end
      elsif status_before == "second_count" && two == 0
        if three != 0
          self.third_count!
        else
          self.completed!
        end
        status = self.status
      elsif status_before == "third_count" && three == 0
        self.completed!
        status = self.status
      elsif status_before == "fourth_count" && four == 0
        self.completed!
        status = self.status
      end

      if self.completed?
        self.calculate_accuracy
      end

      if status == ""
        # status_changed = true
        self.status = status_before
        self.save(validate: false)
      # else
      #   status_changed = false
      end

      # msg = {
      #   id: self.id,
      #   status: status,
      #   status_changed: status_changed,
      #   first_count_pending: one,
      #   second_count_pending: two,
      #   third_count_pending: three,
      #   fourth_count_pending: four
      # }
      # $redis.publish "count_status_#{self.id}", msg.to_json
    end
  end

  def generate_fourth_results
    if !self.calculating?
      self.calculating!
      if fourth_count_released?
        counts_products.where("combined_count = false").each do |cp|
          if cp.results.size == 3
            Result.new(
              count_product_id: cp.id,
              order: 4,
            ).save!
          end
        end
        self.fourth_count!
      end
    end
  end

  def employees_to_report
    temp_employees = []
    employees.each do |employee|
      temp_employees << {
        "name": employee.name,
        "counted_products": employee.counted_products(id)
      }
    end
    temp_employees
  end

  def self.to_csv(count)
    cols = [
      "EMPRESA","COD","MATERIAL","UND","VLR UNIT","VLRT TOTAL","SALDO INICIAL",
      "CONT 1","CONT 2","CONT 3","CONT 4","SALDO FINAL","RESULTADO %","RUA","ESTANTE",
      "PRATELEIRA","PALLET","VLR TOTAL FINAL","RESULTADO VLR %", "JUSTIFICATIVA"
    ]

    CSV.generate(headers: true) do |csv|
      csv << cols

      count.counts_products.each do |cp|
        row = []
        row << count.company.fantasy_name #EMPRESA
        row << cp.product.code #COD
        row << cp.product.description #MATERIAL
        row << cp.product.unit_measurement #UND
        row << (cp.product.value.to_s.gsub! '.',',') #VLR UNIT
        row << (cp.total_value.to_s.gsub! '.',',') #VLRT TOTAL
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
        row << (cp.final_total_value.to_s.gsub! '.',',') #VLR TOTAL FINAL
        row << cp.percentage_result_value #RESULTADO VLR %
        row << (cp.ignore?? ((cp.justification != nil)? cp.justification : cp.nonconformity ) : '') #JUSTIFICATIVA
        csv << row
      end
    end
  end

  def to_xlsx
    p = Axlsx::Package.new
    wb = p.workbook

    wb.add_worksheet(:name => "Pessoas") do |sheet|
      sheet.add_row [
        "EMPRESA","COD","MATERIAL","UND","VLR UNIT","VLRT TOTAL","SALDO INICIAL",
        "CONT 1","CONT 2","CONT 3","CONT 4","SALDO FINAL","RESULTADO %","RUA","ESTANTE",
        "PRATELEIRA","PALLET","VLR TOTAL FINAL","RESULTADO VLR %", "JUSTIFICATIVA", "HITÓRICO DE LOCALIZAÇÕES"
      ]
      
      self.counts_products.each do |cp|
        row = []
        row << cp.count.company.fantasy_name #EMPRESA
        row << cp.product.code #COD
        row << cp.product.description #MATERIAL
        row << cp.product.unit_measurement #UND
        row << (cp.product.value.to_s.gsub! '.',',') #VLR UNIT
        row << (cp.total_value.to_s.gsub! '.',',') #VLRT TOTAL
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
        row << (cp.final_total_value.to_s.gsub! '.',',') #VLR TOTAL FINAL
        row << cp.percentage_result_value #RESULTADO VLR %
        row << (cp.ignore?? ((cp.justification != nil)? cp.justification : cp.nonconformity ) : '') #JUSTIFICATIVA
        row << (cp.location_log.blank?? "" : "- #{cp.location_log["log"].join("\n- ")}")
        sheet.add_row row
      end
    end

    return p
  end
  
  def build_csv_enumerator
    header = [
      "COD","MATERIAL","UND","VLR UNIT","VLRT TOTAL","SALDO INICIAL",
      "CONT 1","CONT 2","CONT 3","CONT 4","SALDO FINAL","RESULTADO %","RUA",
      "ESTANTE","PRATELEIRA","VLR TOTAL FINAL","RESULTADO VLR %"
    ]
    Enumerator.new do |y|
      CsvBuilder.new(header, self, y).build
    end
  end

  def calculate_accuracy
    counts_products.each { |cp| cp.calculate_attributes_without_delay(false) }
    self.calculate_initial_value
    self.calculate_final_value
    self.accuracy = ((self.final_value)*100)/(self.initial_value)
    accuracy_by_stock_ = 0
    counts_products.each do |cp|
      accuracy_by_stock_ += cp.percentage_result
    end
    self.accuracy_by_stock = accuracy_by_stock_ / counts_products.size
    self.save(validate: false)
  end

  def calculate_final_value
    final_value_ = 0
    final_stock_ = 0
    counts_products.where(combined_count: true).each do |cp|
      final_value_ += cp.final_total_value
      final_stock_ += (cp.results.blank?? 0 : cp.results.order(:order).last.quantity_found)
    end
    self.final_value = final_value_
    self.final_stock = final_stock_
    save(validate: false)
  end

  def calculate_initial_value
    initial_value = 0
    initial_stock = 0
    counts_products.each do |cp|
      initial_value += cp.product.value * cp.product.current_stock
      initial_stock += cp.product.current_stock
    end
    save(validate: false)
  end

  def generate_report(content_type = "xlsx")
    @report = reports.find_by(content_type: content_type)
    if !@report.present?
      @report = Report.new
      @report.count_id = self.id
    end
    if @report.present? && !@report.generating?
      @report.filename = "relatorio_contagem_#{(!(self.company.fantasy_name.include? " ") == false)? (self.company.fantasy_name.gsub! " ", "_") : (self.company.fantasy_name)}_#{self.date.strftime("%d-%m-%Y")}.#{content_type}"
      @report.content_type = content_type
      @report.generating!
      
      if content_type == "pdf"
        pdf_html = ActionController::Base.new.render_to_string(template: 'counts/report.html.erb',:locals => {count: self})
        @report.file_contents = WickedPdf.new.pdf_from_string(pdf_html)
      elsif content_type == "xlsx"
        @report.file_contents = self.to_xlsx
      else
        @report.file_contents = Count.to_csv(self)
      end
      @report.completed!
    end
  end

  def question_result(ids)
    if !self.calculating?
      self.calculating!
      CountProduct.question_result(ids)
      counts_products.where("combined_count = false").each do |cp|
        if !cp.results.find_by(order: 4).present?
          Result.new(
            count_product_id: cp.id,
            order: 4,
          ).save!
        else
          r = cp.results.order(:order).last
          r.quantity_found = -1
          r.save
          if !cp.product.location.blank? && !cp.product.location["step"].blank?
            product = cp.product
            product.location.delete("step")
            product.save
          end
          if !cp.product.location.blank? && !cp.product.location["counted_on_step"].blank?
            product = cp.product
            product.location.delete("counted_on_step")
            product.save
          end
        end
      end
      self.fourth_count!
    end
  end

  def divide_products_lists
    if !self.dividing?
      self.dividing!
      ids_ = self.product_ids.shuffle
      employees_ = self.counts_employees
      module_ = (ids_.size % employees_.size) - 1
      each_ = ids_.size / employees_.size
      end_ = -1
      employees_.each_with_index do |ce,index|
        start_ = end_ + 1
        end_ = start_ + each_ - 1
        if index <= module_
          end_+=1
        end
        ce.products = {"products": ids_[start_..end_]}
        ce.save
      end
      self.save(validate: false)
      self.divided!
    end
  end

  def redistribute_products_lists
    if !self.dividing?
      self.dividing!
      previus = counts_employees.last.products
      counts_employees.each do |ce|
        temp = ce.products
        ce.products = previus
        previus = temp
        ce.save
      end
      self.redistributed!
    end
  end

  def delegate_employee_to_third_count(ids)
    CountEmployee.set_employees_to_third_count(ids)
    ids_ = counts_products.where('combined_count = false').map { |cp| cp.product_id }
    self.counts_employees.each do |ce|
      ce.products = {"products": []}
      ce.save
    end
    employees_ = counts_employees.where("in_third_count = true")
    module_ = (ids_.size % employees_.size) - 1
    each_ = ids_.size / employees_.size
    end_ = -1
    employees_.each_with_index do |ce,index|
      start_ = end_ + 1
      end_ = start_ + each_ - 1
      if index <= module_
        end_+=1
      end
      ce.products = {"products": ids_[start_..end_]}
      ce.save
    end
  end

  def complete_products_step
    counts_products.where(combined_count: false).each do |cp|
      cp.combined_count = true
      cp.save(validate: false)
    end
  end

  def can_create
    if user.role.description != "master"
      if user.role.description == "dependent"
        permission = user.user.role.permissions
        quantity = Count.where("user_id in (?) and date >= ?", [user.user.id] + user.user.user_ids, DateTime.now.days_ago(30)).count
      else
        permission = user.role.permissions
        quantity = Count.where("user_id in (?) and date >= ?", [user.id] + user.user_ids, DateTime.now.days_ago(30)).count
      end
      if(permission["counts_per_mounth"] <= quantity)
        errors.add(:user, ", você atingiu a quantidade limite de contagens mensais para o seu plano")
      end
    end
  end

  def verify_if_exist_incomplete
    if company.counts.where("status != 5").count > 0
      errors.add(:user, ", você possui uma contagem incompleta, conclua ela antes de criar uma nova")
    end
  end
  
  # Define asynchronous tasks
  handle_asynchronously :prepare_count
  handle_asynchronously :verify_count
  handle_asynchronously :generate_fourth_results
  handle_asynchronously :generate_report
  handle_asynchronously :complete_products_step
  handle_asynchronously :calculate_accuracy
  handle_asynchronously :delegate_employee_to_third_count
end
