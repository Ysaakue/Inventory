class Role < ApplicationRecord
  has_many :users

  def as_json options={}
    {
      id: id,
      description: description,
      permissions: permissions
    }
  end
end
