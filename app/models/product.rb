class Product < ApplicationRecord
  belongs_to :company
  has_many :counts_products, class_name: "CountProduct"

  validates :code, uniqueness: { scope: :company, message: "Um produto com esse código já foi cadastrado para essa empresa" }
  validate :can_create, on: :create

  after_update :order_locations

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
      if(permission["products"] <= quantity)
        errors.add(:user, ", você atingiu a quantidade limite de produtos para o seu plano")
      end
    end
  end

  def order_locations
    if !location.blank? && !location["locations"].blank? && location["locations"].size > 1
      location["locations"] = quicksort(location["locations"],0,location["locations"].size-1)
    end
  end

  private
  # the functions quicksort and partition reference: https://medium.com/@andrewsouthard1/quicksort-implementation-in-ruby-92de12470efd
  def quicksort(arr, first, last)
    if first < last
      p_index = partition(arr, first, last)
      quicksort(arr, first, p_index - 1)
      quicksort(arr, p_index + 1, last)
    end
  
    arr
  end
  
  def partition(arr, first, last)
    # first select one element from the list, can be any element. 
    # rearrange the list so all elements less than pivot are left of it, elements greater than pivot are right of it.
    pivot = arr[last]
    p_index = first
    
    i = first
    while i < last
      if  ( !arr[i].blank? && !pivot.blank?) && (
            !arr[i]["street"].blank? && !pivot["street"].blank? &&
            arr[i]["street"] < pivot["street"]
          ) || (
            !arr[i]["street"].blank? && !pivot["street"].blank? &&
            !arr[i]["stand"].blank? && !pivot["stand"].blank? &&
            arr[i]["street"] == pivot["street"] && 
            arr[i]["stand"] < pivot["stand"]
          ) || (
            !arr[i]["street"].blank? && !pivot["street"].blank? &&
            !arr[i]["stand"].blank? && !pivot["stand"].blank? &&
            !arr[i]["shelf"].blank? && !pivot["shelf"].blank? &&
            arr[i]["street"] == pivot["street"] && 
            arr[i]["stand"] == pivot["stand"] &&
            arr[i]["shelf"] <= pivot["shelf"] 
          ) || (
            !arr[i]["pallet"].blank? && !pivot["pallet"].blank? &&
            arr[i]["pallet"] <= pivot["pallet"]
          )
        temp = arr[i]
        arr[i] = arr[p_index]
        arr[p_index] = temp
        p_index += 1
      end
      i += 1
    end
    temp = arr[p_index]
    arr[p_index] = pivot
    arr[last] = temp
    return p_index
  end

  handle_asynchronously :order_locations
end
