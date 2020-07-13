class City < ApplicationRecord
  belongs_to :state

  def as_json options={}
    {
      id: id,
      name: name,
      state: state.name
    }
  end
end
