class Api::ResourcesController < Api::ApplicationController
  def index
    # persona = Persona.find_by_token("access_token", token)
    # return access_token_invalid unless persona
    # res_data = {}
    # persona.scopes.each do |o|
    #   if (o == "email")
    #     res_data["email"] = persona.account.email
    #   end
    # end
    # return json: res_data
  end

  private

  def access_token_invalid
    # render json: {"error": "invalid_token"}
  end
end
