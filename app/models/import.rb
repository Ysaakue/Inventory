class Import < ApplicationRecord
  belongs_to :client
  after_create :process

  def process
    self.description = "Processando produtos."
    self.save(validate: false)
    total = 0
    created = 0
    edited = 0
    disabled = 0
    self.client.products.each do |product|
      if self.products.select { |product_inside| product_inside["code"] == product.code }.first.blank?
        product.active = false
        product.save!
        disabled+=1
      end
    end
    self.products.each do |product|
      total+=1
      product_created = self.client.products.find_by(code: product["code"])
      if product_created.present?
        product_created.description = product["description"]
        product_created.current_stock = product["current_stock"]
        product_created.value = product["value"].gsub('R$','').gsub(' ','').gsub(',','.').to_f
        product_created.unit_measurement = product["unit_measurement"]
        if product_created.current_stock == 0
          product_created.active = false
        else
          product_created.active = true
        end
        if product_created.save
          edited+=1
        end
      else
        new_product = Product.new(
          description: product["description"],
          code: product["code"],
          current_stock: product["current_stock"],
          value: product["value"].gsub('R$','').gsub(' ','').gsub(',','.').to_f,
          unit_measurement: product["unit_measurement"],
          client_id: self.client_id
        )
        new_product.location = {}
        if new_product.current_stock == 0
          new_product.active = false
        end
        if new_product.save
          created+=1
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
