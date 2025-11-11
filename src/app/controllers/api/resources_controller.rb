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

    if @current_persona.scopes.include?("anyur_aid")
      permitted_data[:anyur_aid] = @current_persona.account.aid
    end

    if @current_persona.scopes.include?("persona_aid")
      permitted_data[:persona_aid] = @current_persona.aid
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

    if @current_persona.scopes.include?("description")
      permitted_data[:description] = @current_persona.account.description
    end

    if @current_persona.scopes.include?("birthday")
      permitted_data[:birthday] = @current_persona.account.birthday
    end

    if @current_persona.scopes.include?("subscription")
      permitted_data[:subscription] = @current_persona.account.active_subscription&.as_json(only: [ :current_period_start, :current_period_end, :subscription_status ]) || { subscription_status: "none" }
      permitted_data[:subscription][:plan] = @current_persona.account.subscription_plan
    end

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

    persona = Persona.findby_token(token, "access_token")

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
