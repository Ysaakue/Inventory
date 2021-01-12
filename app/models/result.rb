class Result < ApplicationRecord
  belongs_to :count_product, class_name: 'CountProduct'
  belongs_to :employee, optional: true
  after_update :verify_result

  def verify_result
    if count_product.count.first_count? && count_product.results.find_by(order: 1).quantity_found != -1
      if !count_product.results.find_by(order: 2).present?
        Result.new(
          count_product_id: count_product.id,
          order: 2,
        ).save!
      end
    elsif count_product.count.second_count? &&
          count_product.results.find_by(order: 1).quantity_found != -1 &&
          count_product.results.find_by(order: 2).quantity_found != -1 &&
          (
            !count_product.product.location["locations"].blank? &&
            !count_product.product.location["counted_on_step"].blank? &&
            count_product.product.location["counted_on_step"].size == count_product.product.location["locations"].size
          )
      if  count_product.results.find_by(order: 1).quantity_found != count_product.results.find_by(order: 2).quantity_found ||
          count_product.results.find_by(order: 1).quantity_found != count_product.product.current_stock ||
          count_product.results.find_by(order: 2).quantity_found != count_product.product.current_stock
        if !count_product.results.find_by(order: 3).present?
          Result.new(
            count_product_id: count_product.id,
            order: 3,
          ).save!
        end
      else # quantity founds are equal
        count_product.combined_count = true
        count_product.save(validate: false)
        count_product.calculate_attributes
      end
    elsif (
            count_product.count.third_count? &&
            count_product.results.find_by(order: 3).quantity_found != -1 &&
            (
              !count_product.product.location["locations"].blank? &&
              !count_product.product.location["counted_on_step"].blank? &&
              count_product.product.location["counted_on_step"].size == count_product.product.location["locations"].size
            )
          ) || (
            count_product.count.fourth_count?
            count_product.results.find_by(order: 4).quantity_found != -1 &&
            (
              !count_product.product.location["locations"].blank? &&
              !count_product.product.location["counted_on_step"].blank? &&
              count_product.product.location["counted_on_step"].size == count_product.product.location["locations"].size
            )
          )
      count_product.combined_count = true
      count_product.save!
      count_product.calculate_attributes
    end
  end

  def as_json options={}
    {
      order: order,
      quantity_found: quantity_found,
      employee: (employee.blank?? '' : employee.name)
    }
  end
  
  # Define asynchronous tasks
  handle_asynchronously :verify_result
end
