class Api::ResourcesController < Api::ApplicationController
  before_action :authenticate_with_token!, except: :root

  def root
    render json: {
      status: "success",
      message: "ANYUR API",
      data: {
        "services": [
          "Amiverse",
          "IVECOLOR",
          "KISANA_ME",
          "Be_Alive",
          "x_ekusu"
        ]
      }
    }
  end

  def index
    permitted_data = {}

    if @current_persona.scopes.include?("id")
      permitted_data[:id] = @current_persona.account.aid
    end

    if @current_persona.scopes.include?("email")
      permitted_data[:email] = @current_persona.account.email
    end

    if @current_persona.scopes.include?("name")
      permitted_data[:name] = @current_persona.account.name
    end

    if @current_persona.scopes.include?("name_id")
      permitted_data[:name_id] = @current_persona.account.name_id
    end

    # if @current_persona.scopes.include?("profile")
    #   permitted_data[:profile] = @current_persona.account.profile
    # end

    render json: {
      status: "success",
      data: permitted_data
    }
  end

  private

  def authenticate_with_token!
    auth_header = request.headers["Authorization"]

    unless auth_header&.start_with?("Bearer ")
      return render_unauthorized("Missing or malformed Authorization header")
    end

    token = auth_header.split(" ").last

    persona = Persona.find_by_token("access_token", token)

    if persona.nil?
      return render_unauthorized("Invalid or expired token")
    end

    @current_persona = persona
  end

  def render_unauthorized(message)
    render json: {
      status: "error",
      error: "unauthorized",
      message: message
    }, status: :unauthorized
  end
end