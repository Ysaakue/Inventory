class CountProduct < ApplicationRecord
  belongs_to :count
  belongs_to :product
  has_many :results, class_name: 'Result'

  def calculate_attributes(update_count=true)
    accuracy = (self.results.last.quantity_found*100)/self.product.current_stock
    if accuracy > 100
      difference = accuracy - 100
      accuracy = 100 - difference
    end
    self.percentage_result = accuracy
    self.final_total_value = self.results.last.quantity_found * self.product.value
    self.percentage_result_value = ((self.results.last.quantity_found * self.product.value)*100)/(self.product.current_stock * self.product.value)
    self.save(validate: false)
    if update_count
      @count = self.count
      @count.final_value += self.final_total_value
      @count.accuracy = ((self.count.final_value)*100)/(self.count.initial_value)
      @count.save(validate: false)
    end
  end

  def as_json options={}
    simple = if options && options.key?(:simple)
      options[:simple]
    end
    if simple
      {
        product_code: product.code,
        product_description: product.description,
        location_data: product.location,
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
        total_value: total_value,
        percentage_result: percentage_result,
        final_total_value: final_total_value,
        percentage_result_value: percentage_result_value,
        locations: (!product.location.blank? && !product.location["locations"].blank?)? product.location["locations"] : [],
        quantity_found: results
      }
    end
  end

  def self.question_result(ids)
    sql = "update count_products set combined_count = false where product_id in (#{ids.join(',')}) "
    result = ActiveRecord::Base.connection.exec_query(sql)
  end

  def reset_results
    results.destroy_all
  end

  # Define asynchronous tasks
  handle_asynchronously :calculate_attributes
  handle_asynchronously :reset_results
end
