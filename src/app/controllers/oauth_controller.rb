class OauthController < ApplicationController
  before_action :signedin_account, except: :token
  before_action :email_verified_account, except: :token
  skip_before_action :verify_authenticity_token, only: :token



  def authorize
    @error = nil
    @service = nil

    check_authorize_params
    return render :authorize, status: :unprocessable_entity if @error

    @personas = Persona.where(
      account: @current_account,
      service: @service,
      status: 0,
      deleted: false
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

    if params[:persona_id] == "none"
      personas = Persona.where(
        account: @current_account,
        service: @service,
        status: 0,
        deleted: false
      )
      if personas.size >= 2
          @error = "連携を作成できません/作成可能な連携は最大2つです"
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
        id: params[:persona_id],
        status: 0,
        deleted: false
      )
    end
    unless @persona
      @error = "連携が見つかりません"
      return render :authorize, status: :unprocessable_entity
    end
    authorization_code = @persona.generate_token("authorization_code", 10.minutes)
    @persona.scopes = (params[:scope] || "").split(" ")
    unless @persona.save
      @error = "連携を保存できません"
      return render :authorize, status: :unprocessable_entity
    end
    callback = "#{params[:redirect_uri]}?code=#{authorization_code}&state=#{params[:state]}"
    return redirect_to callback, allow_other_host: true
  end



  def token
    if params[:grant_type] != "authorization_code"
      return render json: { error: "unsupported_grant_type" }, status: 400
    end

    client_id = params[:client_id]# || basic_auth_client_id
    client_secret = params[:client_secret]# || basic_auth_client_secret

    service = Service.find_by_token("client_secret", client_secret)
    unless service && service.name_id == client_id
      return render json: { error: "invalid_client" }, status: 401
    end

    # redirect_uriチェック
    begin
      input_uri = URI.parse(params[:redirect_uri])
    rescue URI::InvalidURIError
      return render json: { error: "invalid_redirect_uri" }, status: 401
    end
    unless input_uri.host == service.host
      return render json: { error: "redirect_uri_host_mismatch" }, status: 401
    end

    # personaを探す
    persona = Persona.find_by_token("authorization_code", params[:code])
    unless persona
      return render json: { error: "invalid_code" }, status: 401
    end

    # access token発行
    access_token = persona.generate_token("access_token", 10.minutes)
    refresh_token = persona.generate_token("refresh_token", 30.days)
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



  private



  def check_authorize_params
    # 1. response_type チェック
    unless params[:response_type] == "code"
      @error = "unsupported_response_type"
      return
    end

    # 2. クライアント（サービス）を探す
    service = Service.find_by(name_id: params[:client_id], status: 0, deleted: false)
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

    unless input_uri.host == service.host
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
