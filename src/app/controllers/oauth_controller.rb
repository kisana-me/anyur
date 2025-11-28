class OauthController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :token
  before_action :require_signin, except: :token



  def authorize
    @error = nil
    @service = nil

    check_authorize_params
    return render :authorize, status: :unprocessable_entity if @error

    @personas = Persona.where(
      account: @current_account,
      service: @service,
      status: 0
    )
    @persona = Persona.new

    render :authorize, status: :unprocessable_entity
  end



  def post_authorize
    @error = nil
    @service = nil

    check_authorize_params
    return render :authorize, status: :unprocessable_entity if @error

    @persona = nil

    if params[:persona_aid] == "none"
      personas = Persona.where(
        account: @current_account,
        service: @service,
        status: 0
      )
      if personas.size >= 1
          @error = "連携を作成できません/作成可能な連携は最大1つです"
          return render :authorize, status: :unprocessable_entity
      else
        @persona = Persona.new(name: params[:persona_name])
        @persona.account = @current_account
        @persona.service = @service
        unless @persona.save
          @error = "連携を作成できません/#{@persona.errors.first.full_message}"
          return render :authorize, status: :unprocessable_entity
        end
      end
    else
      @persona = Persona.find_by(
        account: @current_account,
        aid: params[:persona_aid],
        status: 0
      )
    end
    unless @persona
      @error = "連携が見つかりません"
      return render :authorize, status: :unprocessable_entity
    end
    authorization_code = @persona.generate_token(10.minutes, "authorization_code")
    @persona.scopes = (params[:scope] || "").split(" ")
    unless @persona.save
      @error = "連携を保存できません"
      return render :authorize, status: :unprocessable_entity
    end
    callback = "#{params[:redirect_uri]}?code=#{authorization_code}&state=#{params[:state]}"
    redirect_to callback, allow_other_host: true
  end



  def token
    if params[:grant_type] == "authorization_code"
      handle_authorization_code
    elsif params[:grant_type] == "refresh_token"
      handle_refresh_token
    else
      render json: { error: "unsupported_grant_type" }, status: 400
    end
  end



  private



  def handle_authorization_code
    # clientを検証
    client_id = params[:client_id]# || basic_auth_client_id
    client_secret = params[:client_secret]# || basic_auth_client_secret

    service = Service.findby_token(client_secret, "client_secret")
    unless service && service.name_id == client_id
      return render json: { error: "invalid_client" }, status: 401
    end

    # redirect_uriチェック
    begin
      input_uri = URI.parse(params[:redirect_uri])
    rescue URI::InvalidURIError
      return render json: { error: "invalid_redirect_uri" }, status: 401
    end
    unless input_uri.host == service.host || input_uri.host == "localhost"
      return render json: { error: "redirect_uri_host_mismatch" }, status: 401
    end

    # personaを探す
    persona = Persona.findby_token(params[:code], "authorization_code")
    unless persona
      return render json: { error: "invalid_code" }, status: 401
    end

    # token発行
    access_token = persona.generate_token(10.minutes, "access_token")
    refresh_token = persona.generate_token(30.days, "refresh_token")
    persona.authorization_code_expires_at = Time.current
    unless persona.save
      return render json: { error: "server_error" }, status: 401
    end

    # 返却
    render json: {
      access_token: access_token,
      token_type: "Bearer",
      expires_in: 600,
      refresh_token: refresh_token,
      scope: persona.scopes.join(" ")
    }
  end



  def handle_refresh_token
    # 必須項目
    # grant_type: "refresh_token"
    # client_id: "client_id"
    # client_secret: "client_secret"
    # refresh_token "refresh_token"
    # undefinedだと500エラーでhtml帰る

    # clientを検証
    client_id = params[:client_id]# || basic_auth_client_id
    client_secret = params[:client_secret]# || basic_auth_client_secret
    service = Service.findby_token(client_secret, "client_secret")
    unless service && service.name_id == client_id
      return render json: { error: "invalid_client" }, status: 401
    end

    # personaを探す
    persona = Persona.findby_token(params[:refresh_token], "refresh_token")
    unless persona
      return render json: { error: "invalid_refresh_token" }, status: 401
    end

    # token発行
    access_token = persona.generate_token(10.minutes, "access_token")
    refresh_token = persona.generate_token(30.days, "refresh_token")
    persona.authorization_code_expires_at = Time.current
    unless persona.save
      return render json: { error: "server_error" }, status: 401
    end

    # 返却
    render json: {
      access_token: access_token,
      token_type: "Bearer",
      expires_in: 600,
      refresh_token: refresh_token,
      scope: persona.scopes.join(" ")
    }
  end



  def check_authorize_params
    # 1. response_type チェック
    unless params[:response_type] == "code"
      @error = "unsupported_response_type"
      return
    end

    # 2. クライアント（サービス）を探す
    service = Service.is_normal.find_by(name_id: params[:client_id])
    unless service
      @error = "invalid_client"
      return
    end

    # 3. redirect_uri の構文と host チェック
    begin
      input_uri = URI.parse(params[:redirect_uri])
    rescue URI::InvalidURIError
      @error = "invalid_redirect_uri"
      return
    end

    unless input_uri.host == service.host || input_uri.host == "localhost"
      @error = "redirect_uri_host_mismatch"
      return
    end

    # 4. redirect_uri が許可リストに含まれているか
    unless service.redirect_uris.include?(params[:redirect_uri])
      @error = "redirect_uri_not_allowed"
      return
    end

    # 5. scope チェック
    requested_scopes = (params[:scope] || "").split(" ")
    if requested_scopes.empty? || (requested_scopes - service.scopes).any?
      @error = "invalid_scope"
      return
    end

    @service = service
  end
end
