# frozen_string_literal: true

class User < ActiveRecord::Base
  # Include default devise modules.
  #Others available are: :confirmable,:lockable,:timeoutable,:omniauthable
  devise  :database_authenticatable,:registerable,:recoverable,:rememberable,
          :trackable,:validatable
  include DeviseTokenAuth::Concerns::User
  
  has_many :employees

  enum role: [
    :inventory1,  #plan 1
    :inventory2,  #plan 2
    :inventory3,  #plan 3
    :custom,      #custom plan
    :dependent,   #aditional account to a plan
    :master       #NT account
  ]

  def as_json options={}
    {
      id: id,
      name: name,
      email: email,
      role: role,
      uid: uid,
      allow_password_change: allow_password_change,
      first_access: (sign_in_count == 0)
    }
  end
end
