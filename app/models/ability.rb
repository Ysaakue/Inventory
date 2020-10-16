# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    alias_action :pending_products,:submit_quantity_found,:index_by_employee,:identify_employee, to: :mobile_app
    can :mobile_app, :all
    if user.present?
      if user.admin?
        can :manage, :all
      else
        can :manage, [:employee,:count,:import,:product]
        can :update, [:client]
      end
    end
  end
end
