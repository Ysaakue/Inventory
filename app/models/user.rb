# frozen_string_literal: true

class User < ActiveRecord::Base
  # Include default devise modules.
  #Others available are: :confirmable,:lockable,:timeoutable,:omniauthable
  devise  :database_authenticatable,:registerable,:recoverable,:rememberable,
          :trackable,:validatable
  include DeviseTokenAuth::Concerns::User
  
  has_many :employees
  has_many :companies
  has_many :users
  belongs_to :role
  belongs_to :user, optional: true

  validates :user, presence: true, if: :need_user?
  validate :can_create, on: :create

  def as_json options={}
    {
      id: id,
      name: name,
      email: email,
      role: (role.blank?? "" : role.description),
      uid: uid,
      allow_password_change: allow_password_change,
      first_access: (sign_in_count == 0),
      suspended: suspended
    }
  end

  def need_user?
    if !role.blank? && role.description != "dependent"
      return false
    end
    return true
  end

  def master?
    role.blank?? false : role.description == "master"
  end

  def can_create
    if user.role.description != "master"
      if user.role.description == "dependet"
        permission = user.user.role.permissions
        quantity = User.where("user_id in (?)", [user.user.id] + user.user.user_ids).count
      else
        permission = user.role.permissions
        quantity = User.where("user_id in (?)", [user.id] + user.user_ids).count
      end
      if(permission["users"] >= quantity)
        errors.add(:user, ", você atingiu a quantidade limite de usuários para o seu plano")
      end
    end
  end
end
