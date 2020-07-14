class Employee < ApplicationRecord
  has_and_belongs_to_many :counts, join_table: "counts_employees"

  validates :name, presence: { message: "Nome não pode ficar em branco" }
  validates :cpf, presence: { message: "CPF não pode ficar em branco" }

  def as_json options={}
    {
      id: id,
      name: name,
      cpf: cpf
    }
  end
end
