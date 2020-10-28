# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    alias_action :pending_products,:submit_quantity_found,:index_by_employee,:identify_employee, to: :mobile_app
    can :mobile_app, :all
    alias_action :report_download, to: :dont_need_authentication
    can :dont_need_authentication, :all

    if user.present?
      if user.admin?
        can :manage, :all
      else
        can :read, :all
        can :manage, [Employee,Count,Import,Product]
        can :update, [Client]
      end
    end
  end
end
