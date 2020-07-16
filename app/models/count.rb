class Count < ApplicationRecord
  belongs_to :client
  has_and_belongs_to_many :employees, join_table: "counts_employees"
  has_many :counts_products, class_name: "CountProduct"
  after_create :prepare_count
  after_update :verify_count

  enum status: [
    :first_count,
    :second_count,
    :third_count,
    :fourth_count,
    :completed
  ]

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
    elsif self.second_count? && two == 0
      if three != 0
        self.third_count!
      else
        self.completed!
      end
      self.save!
    elsif self.third_count? && three == 0
      if four != 0
        self.fourth_count!
      else
        self.completed!
      end
      self.save!
    elsif self.fourth_count? && four == 0
      self.completed!
      self.save!
    end
  end

  def as_json option={}
    {
      id: id,
      date: date,
      status: status,
      client: client.fantasy_name,
      products: counts_products
    }
  end

  # Define asynchronous tasks
  handle_asynchronously :prepare_count
  handle_asynchronously :verify_count
end
