class Product < ApplicationRecord
  belongs_to :company
  has_many :counts_products, class_name: "CountProduct"

  validates :code, uniqueness: { scope: :company, message: "Um produto com esse código já foi cadastrado para essa empresa" }

  def as_json options={}
    if options   
      if options.key?(:import)
        import = options[:import]
      elsif options.key?(:simple)
        simple = options[:simple]
      end
    end
    if import
      {
        description: description,
        code: code,
        current_stock: current_stock,
        value: value,
        unit_measurement: unit_measurement
      }
    elsif simple
      {
        id: id,
        code: code,
        description: description
      }
    else
      {
        id: id,
        code: code,
        description: description,
        current_stock: current_stock,
        unit_measurement: unit_measurement,
        value: value,
        active: active,
        new: new,
        company: company.fantasy_name,
        location: location
      }
    end
  end

  def self.set_not_new(ids)
    sql = "update products set new = false where id in (#{ids.join(',')}) "
    result = ActiveRecord::Base.connection.exec_query(sql)
  end

  def self.clear_location(company_id)
    sql = "update products as p set location = '{}' where p.company_id = #{company_id}"
    result = ActiveRecord::Base.connection.exec_query(sql)
  end

  def process_locations(streets,stands,shelfs,pallets)
    self.location = {
      id: 0,
      locations: []
    }
    Range.new(0,[streets.size,stands.size,shelfs.size].min - 1).each do |index|
      self.location["locations"] << {
        "street": streets[index],
        "stand": stands[index],
        "shelf": shelfs[index]
      }
    end
    pallets.each { |pallet| self.location["locations"] << pallet }
  end
end
