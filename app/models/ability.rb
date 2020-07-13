# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    if user.present?
      can :manage, :all
    else
      can [:read,:update], :all
    end
  end
end
