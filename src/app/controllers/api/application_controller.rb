class Api::ApplicationController < ApplicationController
  # before_action :check_client

  def token_expired
  end

  private

  def check_client
    # @service = Service.find_by_token("client_secret", params[:client_secret])
    # return json: {"error": "invalid_client"} unless @service
  end
end