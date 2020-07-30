class Count < ApplicationRecord
  belongs_to :client
  has_and_belongs_to_many :employees, join_table: "counts_employees"
  has_many :counts_products, class_name: "CountProduct"
  after_create :prepare_count
  after_update :verify_count

  validate :date_not_retrograde

  enum status: [
    :first_count,
    :second_count,
    :third_count,
    :fourth_count_pending,
    :fourth_count,
    :completed
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
        products: counts_products
      }
    end
  end


  def prepare_count
    self.client.products.each do |product|
      cp = CountProduct.new(
        product_id: product.id,
        count_id: self.id,
        combined_count: false
      )
      cp.save!
    end
    self.counts_products.each do |cp|
      r = Result.new(
        count_product_id: cp.id,
        order: 1,
      )
      r.save!
    end
  end

  def verify_count
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
        elsif cp.results.size == 3
          three+=1
        elsif cp.results.size == 1
          four+=1
        end
      end
    end
    if self.first_count? && one == 0
      self.second_count!
      self.save!
      status = self.status
    elsif self.second_count? && two == 0
      if three != 0
        self.third_count!
      else
        self.completed!
      end
      self.save!
      status = self.status
    elsif self.third_count? && three == 0
      if four != 0
        self.fourth_count_pending!
      else
        self.completed!
      end
      self.save!
      status = self.status
    elsif self.fourth_count? && four == 0
      self.completed!
      self.save!
      status = self.status
    end

    if status != ""
      msg = {
        id: self.id,
        status: status
      }
      $redis.publish "count_status_#{self.id}", msg.to_json
    end
  end

  def generate_fourth_results
    if fourth_count_pending? && fourth_count_released?
      cps = counts_products.where("combined_count = false")
      cps.each do |cp|
        if cp.results.size == 3
          Result.new(
            count_product_id: cp.id,
            order: 4,
          ).save!
        end
      end
      @count.fourth_count!
      @count.save(validate: false)
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

  # Define asynchronous tasks
  handle_asynchronously :prepare_count
  handle_asynchronously :verify_count
  handle_asynchronously :generate_fourth_results
end
