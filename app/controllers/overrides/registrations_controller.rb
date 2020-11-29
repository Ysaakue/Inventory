# frozen_string_literal: true

module Overrides
  class RegistrationsController < DeviseTokenAuth::RegistrationsController

    def create
      render json:{
        status: "error",
        "message": "Você não está autorizado a acessar essa página"
      }, status: 401
    end
  end
end
