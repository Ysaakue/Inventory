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
    status = "calculating"
    save(validate: false)
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
      product.location.delete("step")
      product.location.delete("counted_on_step")
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
    status = "first_count"
    save(validate: false)
  end

  def verify_count
    if !self.calculating?
      status_before = self.status
      self.status = "calculating"
      self.save(validate: false)
      one = 0
      two = 0
      three = 0
      four = 0
      status = ""
      self.counts_products.where(ignore: false).each do |cp|
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
        self.status = "second_count"
        self.save(validate: false)
        status = self.status
        if self.divided?
          self.redistribute_products_lists
        end
      elsif status_before == "second_count" && two == 0
        if three != 0
          self.status = "third_count"
          if self.divided?
            self.delegate_employee_to_third_count
          end
        else
          self.status = "completed"
        end
        self.save(validate: false)
        status = self.status
      elsif status_before == "third_count" && three == 0
        if four != 0
          self.status = "fourth_count_pending"
        else
          self.status = "completed"
        end
        self.save(validate: false)
        status = self.status
      elsif status_before == "fourth_count" && four == 0
        self.status = "completed"
        self.save(validate: false)
        status = self.status
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
    self.status = "calculating"
    self.save(validate: false)
    if fourth_count_released?
      cps = counts_products.where("combined_count = false")
      cps.each do |cp|
        if cp.results.size == 3
          Result.new(
            count_product_id: cp.id,
            order: 4,
          ).save!
        end
      end
      self.status = "fourth_count"
      self.save(validate: false)
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
        row << (('%.2f' % cp.product.value).gsub! '.',',') #VLR UNIT
        row << (('%.2f' % cp.total_value).gsub! '.',',') #VLRT TOTAL
        row << cp.product.current_stock #SALDO INICIAL
        row << ((cp.results.order(:order)[0].blank? || cp.results.order(:order)[0].quantity_found < 0)? '-' : cp.results.order(:order)[0].quantity_found) #CONT 1
        row << ((cp.results.order(:order)[1].blank? || cp.results.order(:order)[1].quantity_found < 0)? '-' : cp.results.order(:order)[1].quantity_found) #CONT 2
        row << ((cp.results.order(:order)[2].blank? || cp.results.order(:order)[2].quantity_found < 0)? '-' : cp.results.order(:order)[2].quantity_found) #CONT 3
        row << ((cp.results.order(:order)[3].blank? || cp.results.order(:order)[3].quantity_found < 0)? '-' : cp.results.order(:order)[3].quantity_found) #CONT 4
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
        row << (('%.2f' % cp.final_total_value).gsub! '.',',') #VLR TOTAL FINAL
        row << ('%.2f' % cp.percentage_result_value) #RESULTADO VLR %
        row << (cp.ignore?? ((cp.justification != nil)? cp.justification : cp.nonconformity ) : '') #JUSTIFICATIVA
        csv << row
      end
    end
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
    counts_products.where(ignore: false).each { |cp| cp.calculate_attributes_without_delay(false) }
    self.calculate_initial_value
    self.calculate_final_value
    accuracy_ = ((self.final_value)*100)/(self.initial_value)
    accuracy_by_stock_ = ((self.final_stock)*100)/(self.initial_stock)
    if accuracy_ > 100
      difference = accuracy_ - 100
      accuracy_ = 100 - difference
    end
    if accuracy_by_stock_ > 100
      difference = accuracy_by_stock_ - 100
      accuracy_by_stock_ = 100 - difference
    end
    self.accuracy = accuracy_
    self.accuracy_by_stock = accuracy_by_stock_
    self.save(validate: false)
  end

  def calculate_final_value
    final_value = 0
    final_stock = 0
    counts_products.where(ignore: false,combined_count: true).each do |cp|
      final_value += cp.final_total_value
      final_stock += cp.results.order(:order).last.quantity_found
    end
    save(validate: false)
  end

  def calculate_initial_value
    initial_value = 0
    initial_stock = 0
    counts_products.where(ignore: false).each do |cp|
      initial_value += cp.product.value * cp.product.current_stock
      initial_stock += cp.product.current_stock
    end
    save(validate: false)
  end

  def generate_report(content_type)
    content_type ||= "csv"
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
      else
        @report.file_contents = Count.to_csv(self)
      end
      @report.status = "completed"
      @report.save!
    end
  end

  def question_result(ids)
    self.status = "calculating"
    self.save(validate: false)
    CountProduct.question_result(ids)
    cps = counts_products.where("combined_count = false")
    cps.each do |cp|
      if cp.results.size <= 3
        Result.new(
          count_product_id: cp.id,
          order: 4,
        ).save!
      else
        r = cp.results.order(:order).last
        r.quantity_found = -1
        r.save
      end
    end
    self.status = "fourth_count"
    self.save(validate: false)
  end

  def divide_products_lists
    ids_ = self.product_ids.shuffle
    employees_ = self.counts_employees
    module_ = (ids_.size % employees_.size) - 1
    each_ = ids_.size / employees_.size
    employees_.each_with_index do |ce,index|
      start_ = index * each_
      if (index <= module_ + 1) && index > 0
        start_+=1
      end
      end_ = start_ + each_ - 1
      if index <= module_
        end_+=1
      end
      ce.products = {"products": ids_[start_..end_]}
      ce.save
    end
    self.divided = true
    self.save(validate: false)
  end

  def redistribute_products_lists
    previus = counts_employees.last.products
    counts_employees.each do |ce|
      temp = ce.products
      ce.products = previus
      previus = temp
      ce.save
    end
  end

  def delegate_employee_to_third_count
    counts_employees.shuffle.each_with_index do |x,index| 
      if index == 0
        x.products["products"] = counts_products.where('combined_count = false').each { |cp| cp.product_id }
      else
        x.products["products"] = []
      end
      x.save
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
      if user.role.description == "dependet"
        permission = user.user.role.permissions
        quantity = Count.where("user_id in (?) and date >= ?", [user.user.id] + user.user.user_ids, DateTime.now.days_ago(30)).count
      else
        permission = user.role.permissions
        quantity = Count.where("user_id in (?) and date >= ?", [user.id] + user.user_ids, DateTime.now.days_ago(30)).count
      end
      if(permission["counts_per_mounth"] >= quantity)
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
  handle_asynchronously :divide_products_lists
  handle_asynchronously :redistribute_products_lists
  handle_asynchronously :complete_products_step
  handle_asynchronously :calculate_accuracy
end
