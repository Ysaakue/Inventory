class Employee < ApplicationRecord
  has_and_belongs_to_many :counts, join_table: "counts_employees"

  validates :name, presence: { message: "Nome não pode ficar em branco" }
  validates :cpf, presence: { message: "CPF não pode ficar em branco" }

  def counted_products(count_id)
    sql = "select count(*) as products from (inventory_development.results inner join inventory_development.count_products ON count_products.id = results.count_product_id) where results.employee_id = #{id} and count_products.count_id = #{count_id}"
    result = ActiveRecord::Base.connection.exec_query(sql)
    result.first["products"]
  end

  def as_json options={}
    {
      id: id,
      name: name,
      cpf: cpf
    }
  end
end
