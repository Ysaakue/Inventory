# frozen_string_literal: true

class User < ActiveRecord::Base
  # Include default devise modules. Others available are: :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,:recoverable, :rememberable, :trackable, :validatable
  include DeviseTokenAuth::Concerns::User
  belongs_to :client, optional: true

  validates :client,presence: true, if: :need_client_id?

  def need_client_id?
    !admin == true
  end

  def as_json options={}
  {
    id: id,
    email: email,
    admin: admin,
    client_id: client_id,
    client_fantasy_name: (client.present?? client.fantasy_name : nil),
    uid: uid,
    allow_password_change: allow_password_change,
    first_access: (sign_in_count == 0)
  }
  end
end
