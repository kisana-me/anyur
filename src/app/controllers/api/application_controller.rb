class Api::ApplicationController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :require_signin

  private

  def check_client
    @current_service = Service.findby_token(params[:client_secret], "client_secret")
    render json: { "error": "invalid_token" } unless @current_service
  end
end
