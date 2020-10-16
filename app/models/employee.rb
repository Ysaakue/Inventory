class Employee < ApplicationRecord
  has_many :counts_employees, class_name: "CountEmployee"
  has_many :counts, through: :counts_employees
  has_many :results
  belongs_to :user

  validates :name, presence: { message: "Nome não pode ficar em branco" }
  validates :cpf, uniqueness: { message: "Já existe um operador com esse CPF" }
  validates :cpf, presence: { message: "CPF não pode ficar em branco" }

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
end
