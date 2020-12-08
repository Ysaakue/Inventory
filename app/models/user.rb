# frozen_string_literal: true

class User < ActiveRecord::Base
  # Include default devise modules.
  #Others available are: :confirmable,:lockable,:timeoutable,:omniauthable
  devise  :database_authenticatable,:registerable,:recoverable,:rememberable,
          :trackable,:validatable
  include DeviseTokenAuth::Concerns::User
  
  has_many :employees
  belongs_to :role
  belongs_to :user, optional: true
  has_many :users

  validates :user, presence: true, if: :need_user?

  def as_json options={}
    {
      id: id,
      name: name,
      email: email,
      role: (role.blank?? "" : role.description),
      uid: uid,
      allow_password_change: allow_password_change,
      first_access: (sign_in_count == 0)
    }
  end

  def need_user?
    if !role.blank? && role.description != "dependent"
      return false
    end
    return true
  end

  def master?
    role.description == "master"
  end
end
