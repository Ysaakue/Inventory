class Company < ApplicationRecord
  has_many :products
  has_many :counts
  has_many :imports
  belongs_to :city
  belongs_to :state
  belogns_to :user

  validates :cnpj, uniqueness: { message: "Já existe uma empresa com esse CNPJ" }
  validates :email, uniqueness: { message: "Já existe uma empresa com esse email" }

  def as_json option={}
    {
      id: id,
      cnpj: cnpj,
      company_name: company_name,
      fantasy_name: fantasy_name,
      state_registration: state_registration,
      email: email,
      contact_name_telephone: contact_name_telephone,
      telephone_number: telephone_number,
      contact_name_cell_phone: contact_name_cell_phone,
      cell_phone_number: cell_phone_number,
      street_name_address: street_name_address,
      number_address: number_address,
      complement_address: complement_address,
      neighborhood_address: neighborhood_address ,
      postal_code_address: postal_code_address,
      state: state.name,
      state_id: state_id,
      city: city.name,
      city_id: city_id,
      dimensions: dimensions
    }
  end
end
