class Employee < ApplicationRecord
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
