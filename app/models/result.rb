class Result < ApplicationRecord
  belongs_to :count_product, class_name: 'CountProduct'
  belongs_to :employee, optional: true
  after_update :verify_result

  def verify_result
    if count_product.results.size == 1 && count_product.results[0].quantity_found != -1
      Result.new(
        count_product_id: count_product.id,
        order: 2,
      ).save!
    elsif count_product.results.size == 2 
      if  count_product.results[0].quantity_found != -1 &&
          count_product.results[1].quantity_found != -1
        if count_product.results[0].quantity_found != count_product.results[1].quantity_found
          Result.new(
            count_product_id: count_product.id,
            order: 3,
          ).save!
        else # quantity founds are equal
          count_product.combined_count = true
          count_product.save!
        end
      end # values != -1
    elsif count_product.results.size == 3 &&
          count_product.results[2].quantity_found != -1
      if  count_product.results[0].quantity_found != count_product.results[1].quantity_found &&
          count_product.results[2].quantity_found != count_product.results[1].quantity_found &&
          count_product.results[0].quantity_found != count_product.results[2].quantity_found
        if count_product.count.fourth_count_released?
          Result.new(
            count_product_id: count_product.id,
            order: 4,
          ).save!
        end
      else
        count_product.combined_count = true
        count_product.save!
      end
    elsif count_product.results[3].quantity_found != -1
      count_product.combined_count = true
      count_product.save!
    end
    count_product.count.verify_count
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
