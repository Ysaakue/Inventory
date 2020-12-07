class Import < ApplicationRecord
  belongs_to :company
  after_create :process

  def process
    self.description = "Processando produtos."
    self.invalid_products = []
    self.save(validate: false)
    total = 0
    created = 0
    edited = 0
    disabled = 0
    self.company.products.each do |product|
      if self.products.select { |product_inside| product_inside["code"] == product.code }.first.blank?
        product.active = false
        product.save!
        disabled+=1
      end
    end
    self.products.each do |product|
      total+=1
      product_created = self.company.products.find_by(code: product["code"])
      if product_created.present?
        product_created.description = (product["description"] != nil)? product["description"] : ""
        product_created.current_stock = (product["current_stock"] != nil)? product["current_stock"] : 0
        product_created.value = product["value"].gsub('R$','').gsub(' ','').gsub(',','.').to_f
        product_created.unit_measurement = (product["unit_measurement"] != nil)? product["unit_measurement"] : ""
        product_created.input = (product["input"] != nil)? product["input"] : 0
        product_created.output = (product["output"] != nil)? product["output"] : 0
        if product_created.current_stock == 0
          product_created.active = false
        else
          product_created.active = true
        end
        product_created.process_locations((product["streets"] != nil)? product["streets"] : [],
                                          (product["stands"] != nil)? product["stands"] : [],
                                          (product["shelfs"] != nil)? product["shelfs"] : [],
                                          (product["pallets"] != nil)? product["pallets"] : [])
        if product_created.save
          edited+=1
        else
          product["errors"] = product_created.errors.full_messages
          self.invalid_products << product
        end
      else
        new_product = Product.new(
          description: (product["description"] != nil)? product["description"] : "",
          code: product["code"],
          current_stock: (product["current_stock"] != nil)? product["current_stock"] : 0,
          value: product["value"].gsub('R$','').gsub(' ','').gsub(',','.').to_f,
          unit_measurement: (product["unit_measurement"] != nil)? product["unit_measurement"] : "",
          company_id: self.company_id,
          input: (product["input"] != nil)? product["input"] : 0,
          output: (product["output"] != nil)? product["output"] : 0
        )
        new_product.process_locations((product["streets"] != nil)? product["streets"] : [],
                                      (product["stands"] != nil)? product["stands"] : [],
                                      (product["shelfs"] != nil)? product["shelfs"] : [],
                                      (product["pallets"] != nil)? product["pallets"] : [])
        if new_product.current_stock == 0
          new_product.active = false
        end
        if new_product.save
          created+=1
        else
          product["errors"] = new_product.errors.full_messages
          self.invalid_products << product
        end
      end
    end
    error = total - (edited+created)
    self.description = "Durante a importação #{
        (disabled > 1 || disabled == 0)? "#{disabled} produtos foram desabilitados" : "#{disabled} produto foi desabilitado"
      }, #{
        (edited > 1 || edited == 0)? "#{edited} produtos foram editados" : "#{edited} produto foi editado"
      },  #{
        (created > 1 || created == 0)? "#{created} produtos foram criados" : "#{created} produto foi criado"
      }, e #{
        (error > 1 || error == 0)? "#{error} produtos apresentaram erros" : "#{error} produto apresentou erro"
      }"
    self.save!
  end

  # Define asynchronous tasks
  handle_asynchronously :process
end
