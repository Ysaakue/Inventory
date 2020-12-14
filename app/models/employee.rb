class Employee < ApplicationRecord
  has_many :counts_employees, class_name: "CountEmployee"
  has_many :counts, through: :counts_employees
  has_many :results
  belongs_to :user

  validates :name, presence: { message: "Nome não pode ficar em branco" }
  validates :cpf, uniqueness: { message: "Já existe um operador com esse CPF" }
  validates :cpf, presence: { message: "CPF não pode ficar em branco" }
  validate :can_create, on: :create

  def counted_products(count_id)
    sql = "select count(*) as products from (results inner join count_products ON count_products.id = results.count_product_id) where results.employee_id = #{id} and count_products.count_id = #{count_id}"
    result = ActiveRecord::Base.connection.exec_query(sql)
    result.first["products"]
  end

  def as_json options={}
    index = if options && options.key?(:index)
      options[:index]
    end
    if index
      {
        id: id,
        name: name,
        cpf: cpf,
        counts: counts.size,
        items_counted: results.size
      }
    else
      {
        id: id,
        name: name,
        cpf: cpf
      }
    end
    
  end

  def can_create
    if user.role.description != "master"
      if user.role.description == "dependet"
        permission = user.user.role.permissions
        quantity = Employee.where("user_id in (?)", [user.user.id] + user.user.user_ids).count
      else
        permission = user.role.permissions
        quantity = Employee.where("user_id in (?)", [user.id] + user.user_ids).count
      end
      if(permission["empoloyees"] >= quantity)
        errors.add(:user, ", você atingiu a quantidade limite de auditores para o seu plano")
      end
    end
  end
end
