class CountProduct < ApplicationRecord
  belongs_to :count
  belongs_to :product
  has_many :results, class_name: 'Result'

  validates :product_id, uniqueness: { scope: :count, message: "Um produto com esse código já foi cadastrado para essa contagem" }

  def calculate_attributes(update_count=true)
    self.percentage_result = ((self.results.blank?? 0 : self.results.order(:order).last.quantity_found)*100)/self.product.current_stock
    self.final_total_value = (self.results.blank?? 0 : self.results.order(:order).last.quantity_found) * self.product.value
    self.percentage_result_value = (((self.results.blank?? 0 : self.results.order(:order).last.quantity_found) * self.product.value)*100)/(self.product.current_stock * self.product.value)
    self.save(validate: false)
    if update_count
      @count = self.count
      @count.final_value += self.final_total_value
      @count.final_stock += (self.results.blank?? 0 : self.results.order(:order).last.quantity_found)
      @count.save(validate: false)
    end
  end

  def as_json options={}
    if options   
      if options.key?(:fake_product)
        fake_product = options[:fake_product]
      elsif options.key?(:simple)
        simple = options[:simple]
      end
    end
    if simple
      {
        product_id: product.id,
        product_code: product.code,
        product_description: product.description,
        location_data: product.location,
        product_unit_measurement: product.unit_measurement,
      }
    elsif fake_product
      {
        id: product.id,
        code: product.code,
        description: product.description,
        unit_measurement: product.unit_measurement
      }
    else
      {
        product_id: product.id,
        product_code: product.code,
        product_description: product.description,
        product_current_stock: product.current_stock,
        product_unit_measurement: product.unit_measurement,
        product_value: product.value,
        ignore: ignore,
        justification: justification,
        nonconformity: nonconformity,
        total_value: total_value,
        percentage_result: percentage_result,
        final_total_value: final_total_value,
        percentage_result_value: percentage_result_value,
        locations: (!product.location.blank? && !product.location["locations"].blank?)? product.location["locations"] : [],
        quantity_found: results.order(:order)
      }
    end
  end

  def question_result(ids)
    sql = "update count_products set combined_count = false where product_id in (#{ids.join(',')}) "
    result = ActiveRecord::Base.connection.execute(sql)
  end

  def reset_results
    results.destroy_all
  end

  # Define asynchronous tasks
  handle_asynchronously :calculate_attributes
end
