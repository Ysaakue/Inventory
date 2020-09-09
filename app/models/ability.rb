# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    alias_action :pending_products,:submit_quantity_found, to: :mobile_app
    can [:read,:update,:mobile_app], :all
    cannot :create, :all
    if user.present?
      can :manage, :all
    end
  end
end
