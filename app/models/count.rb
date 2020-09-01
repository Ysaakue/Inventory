class Count < ApplicationRecord
  belongs_to :client
  has_and_belongs_to_many :employees, join_table: "counts_employees"
  has_many :counts_products, class_name: "CountProduct"
  has_many :products, through: :counts_products
  has_many :reports
  
  after_create :prepare_count

  validate :date_not_retrograde

  enum status: [
    :first_count,
    :second_count,
    :third_count,
    :fourth_count_pending,
    :fourth_count,
    :completed,
    :calculating
  ]

  def date_not_retrograde
    if date < Date.today
      errors.add(:date, "A data não pode ser retrograda")
    end
  end

  def as_json options={}
    index = if options && options.key?(:index)
      options[:index]
    end
    if index
      {
        id: id,
        date: date,
        status: status,
        client: client.fantasy_name,
      }
    else
      {
        id: id,
        date: date,
        status: status,
        client: client.fantasy_name,
        employees: employees,
        products: counts_products
      }
    end
  end

  def prepare_count
    self.status = "calculating"
    self.save(validate: false)
    temp_products = self.client.products.where(active: true)
    if self.products_quantity_to_count < temp_products.size
      temp_products = temp_products.shuffle
      temp_products = temp_products[0..products_quantity_to_count-1]
    end
    initial_value = 0
    temp_products.each do |product|
      total_value = product.value * product.current_stock
      cp = CountProduct.new(
        product_id: product.id,
        count_id: self.id,
        combined_count: false,
        total_value: total_value
      )
      cp.save(validate: false)
      initial_value += cp.total_value
      Result.new(
        count_product_id: cp.id,
        order: 1,
      ).save(validate: false)
    end
    self.initial_value = initial_value
    self.status = "first_count"
    self.save(validate: false)
  end

  def verify_count
    status_before = self.status
    self.status = "calculating"
    self.save(validate: false)
    one = 0
    two = 0
    three = 0
    four = 0
    status = ""
    self.counts_products.each do |cp|
      if !cp.combined_count?
        if cp.results.size == 1
          one+=1
        elsif cp.results.size == 2
          two+=1
        elsif cp.results.size == 3 && cp.results.last.quantity_found == -1
          three+=1
        else
          four+=1
        end
      end
    end
    if status_before == "first_count" && one == 0
      self.status = "second_count"
      self.save(validate: false)
      status = self.status
    elsif status_before == "second_count" && two == 0
      if three != 0
        self.status = "third_count"
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
      "PRATELEIRA","PALLET","VLR TOTAL FINAL","RESULTADO VLR %"
    ]

    CSV.generate(headers: true) do |csv|
      csv << cols

      count.counts_products.each do |cp|
        row = []
        row << count.client.fantasy_name #EMPRESA
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
        row << cp.results.last.quantity_found #SALDO FINAL
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
    self.accuracy = ((self.final_value)*100)/(self.initial_value)
    self.save(validate: false)
  end

  def calculate_final_value
    self.final_value = 0
    self.counts_products.each do |cp|
      self.final_value += cp.final_total_value
    end
    self.save(validate: false)
  end

  def calculate_initial_value
    initial_value = 0
    counts_products.each do |cp|
      initial_value += cp.product.value * cp.product.current_stock
    end
    self.initial_value = initial_value
    self.save(validate: false)
  end

  def generate_report(content_type)
    content_type ||= "csv"
    @report = reports.find_by(content_type: content_type)
    if !@report.present? || (@report.present? && @report.completed?)
      if !@report.present?
        @report = Report.new
        @report.count_id = self.id
      end
      @report.filename = "relatorio_contagem_#{(!(self.client.fantasy_name.include? " ") == false)? (self.client.fantasy_name.gsub! " ", "_") : (self.client.fantasy_name)}_#{self.date.strftime("%d-%m-%Y")}.#{content_type}"
      @report.content_type = content_type
      @report.generating!
      @report.save!
      
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
        cp.combined_count = true
        cp.save
      end
    end
    self.status = "fourth_count"
    self.save(validate: false)
  end

  # Define asynchronous tasks
  handle_asynchronously :prepare_count
  handle_asynchronously :verify_count
  handle_asynchronously :generate_fourth_results
  handle_asynchronously :generate_report
end
