class CountProduct < ApplicationRecord
  belongs_to :count
  belongs_to :product
  has_many :results, class_name: 'Result'

  def calculate_attributes
    self.percentage_result = (self.results.last.quantity_found*100)/self.product.current_stock
    self.final_total_value = self.results.last.quantity_found * self.product.value
    self.percentage_result_value = ((self.results.last.quantity_found * self.product.value)*100)/(self.product.current_stock * self.product.value)
    self.save!
    self.count.final_value += self.final_total_value
    self.count.accuracy = ((self.count.final_value)*100)/(self.count.initial_value)
    self.count.save!
  end

  def as_json options={}
    {
      product_id: product.id,
      product_code: product.code,
      product_description: product.description,
      product_current_stock: product.current_stock,
      product_unit_measurement: product.unit_measurement,
      product_value: product.value,
      total_value: total_value,
      percentage_result: percentage_result,
      final_total_value: final_total_value,
      percentage_result_value: percentage_result_value,
      locations: (!product.location.blank? && !product.location["locations"].blank?)? product.location["locations"] : [],
      quantity_found: results
    }
  end

  # Define asynchronous tasks
  handle_asynchronously :calculate_attributes
end
