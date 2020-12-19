# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    alias_action  :pending_products,:submit_quantity_found,:index_by_employee,
                  :identify_employee,:set_nonconformity,:ignore_product,:remove_location, to: :mobile_app
    can :mobile_app, :all
    alias_action :report_download, to: :dont_need_authentication
    can :dont_need_authentication, :all

    cannot :dashboard, Count

    if user.present?
      if user.master?
        can :manage, :all
      else
        can :read, :all
        can :manage, Company, user_id: user.id
        can :manage, Employee, user_id: user.id
        can :manage, Count, user_id: user.id
        can :manage, Import, company: { user_id: user.id }
        can :manage, Product, company: { user_id: user.id }
        can :manage, User, id: user.id
        can :manage, User, user_id: user.id
      end
    end
  end
end
