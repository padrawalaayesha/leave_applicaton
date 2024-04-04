class Api::V1::HomesController < ApplicationController
  skip_before_action :doorkeeper_authorize!
  def get_authorization_details
    doorkeeper_client = Doorkeeper::Application.last
    render json: {
      doorkeeper: {
        name: doorkeeper_client.name,
        uid: doorkeeper_client.uid,
        secret: doorkeeper_client.secret
      }, status: :ok
    }
  end
end