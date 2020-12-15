class Product < ApplicationRecord
  belongs_to :company
  has_many :counts_products, class_name: "CountProduct"

  validates :code, uniqueness: { scope: :company, message: "Um produto com esse código já foi cadastrado para essa empresa" }
  validate :can_create, on: :create

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
      if streets[index] != "" && stands[index] != "" && shelfs[index] != ""
        self.location["locations"] << {
          "street": streets[index],
          "stand": stands[index],
          "shelf": shelfs[index]
        }
      end
    end
    pallets.each do |pallet|
      if pallet != ""
        self.location["locations"] << { "pallet": pallet }
      end
    end
  end

  def can_create
    if company.user.role.description != "master"
      if company.user.role.description == "dependet"
        permission = company.user.user.role.permissions
        quantity = Products.where("company_id in (?)", Company.where("user_id in (?)", [company.user.user.id] + company.user.user.user_ids).ids).count
      else
        permission = company.user.role.permissions
        quantity = User.where("user_id in (?)", Company.where("user_id in (?)", [company.user.id] + company.user.user_ids).ids).count
      end
      if(permission["products"] >= quantity)
        errors.add(:user, ", você atingiu a quantidade limite de produtos para o seu plano")
      end
    end
  end
end
