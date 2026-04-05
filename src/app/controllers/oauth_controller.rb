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
        service: @service,
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
    bind_authorization_redirect_uri(@persona, params[:redirect_uri])
    @persona.with_challenge(params[:code_challenge].to_s, params[:code_challenge_method].to_s)
    unless @persona.save
      @error = "連携を保存できません"
      return render :authorize, status: :unprocessable_entity
    end
    callback = build_redirect_with_params(
      params[:redirect_uri],
      code: authorization_code,
      state: params[:state]
    )
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
    service = authenticate_client
    unless service
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
    unless service.redirect_uris.include?(params[:redirect_uri])
      return render json: { error: "invalid_redirect_uri" }, status: 401
    end

    # personaを探す
    persona = Persona.findby_token(params[:code], "authorization_code")
    unless persona
      return render json: { error: "invalid_code" }, status: 401
    end
    unless persona.service_id == service.id
      return render json: { error: "invalid_code" }, status: 401
    end
    unless authorization_redirect_uri_matches?(persona, params[:redirect_uri])
      return render json: { error: "invalid_grant" }, status: 401
    end
    unless verify_pkce_for_persona(persona, service)
      return render json: { error: "invalid_grant" }, status: 401
    end

    # token発行
    access_token = persona.generate_token(10.minutes, "access_token")
    refresh_token = persona.generate_token(30.days, "refresh_token")
    persona.authorization_code_expires_at = Time.current
    clear_authorization_redirect_uri(persona)
    persona.with_challenge(nil, nil)
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

    service = authenticate_client
    unless service
      return render json: { error: "invalid_client" }, status: 401
    end

    # personaを探す
    persona = Persona.findby_token(params[:refresh_token], "refresh_token")
    unless persona
      return render json: { error: "invalid_refresh_token" }, status: 401
    end
    unless persona.service_id == service.id
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

    # 6. code_challenge と code_challenge_method を確認(PKCE)
    code_challenge = params[:code_challenge].to_s
    code_challenge_method = params[:code_challenge_method].to_s

    if service.public_client? && code_challenge.blank?
      @error = "invalid_code_challenge"
      return
    end

    if code_challenge.present?
      unless code_challenge_method == "S256"
        @error = "invalid_code_challenge_method"
        return
      end
      unless valid_pkce_code?(code_challenge)
        @error = "invalid_code_challenge"
        return
      end
    elsif code_challenge_method.present?
      @error = "invalid_code_challenge_method"
      return
    end

    @service = service
  end

  def authenticate_client
    client_id = params[:client_id].to_s
    service = Service.is_normal.find_by(name_id: client_id)
    return nil unless service

    if service.confidential_client?
      client_secret = params[:client_secret].to_s
      return nil if client_secret.blank?

      secret_owner = Service.findby_token(client_secret, "client_secret")
      return nil unless secret_owner && secret_owner.id == service.id
    end

    service
  end

  def valid_pkce_code?(value)
    value.match?(/\A[A-Za-z0-9\-._~]{43,128}\z/)
  end

  def verify_pkce_for_persona(persona, service)
    challenge = if persona.meta.is_a?(Hash)
      persona.meta["challenge"]
    end

    if service.public_client?
      return false unless challenge.is_a?(Hash)
    end

    return true unless challenge.is_a?(Hash)

    code_verifier = params[:code_verifier].to_s
    return false unless valid_pkce_code?(code_verifier)
    return false unless challenge["code_challenge_method"] == "S256"

    expected = Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier), padding: false)
    ActiveSupport::SecurityUtils.secure_compare(expected, challenge["code_challenge"].to_s)
  end

  def bind_authorization_redirect_uri(persona, redirect_uri)
    persona.meta = {} unless persona.meta.is_a?(Hash)
    oauth = persona.meta["oauth"]
    oauth = {} unless oauth.is_a?(Hash)
    oauth["authorization_redirect_uri"] = redirect_uri.to_s
    persona.meta["oauth"] = oauth
  end

  def authorization_redirect_uri_matches?(persona, redirect_uri)
    oauth = if persona.meta.is_a?(Hash)
      persona.meta["oauth"]
    end
    return false unless oauth.is_a?(Hash)

    stored_redirect_uri = oauth["authorization_redirect_uri"].to_s
    return false if stored_redirect_uri.blank?

    stored_redirect_uri == redirect_uri.to_s
  end

  def clear_authorization_redirect_uri(persona)
    return unless persona.meta.is_a?(Hash)

    oauth = persona.meta["oauth"]
    return unless oauth.is_a?(Hash)

    oauth.delete("authorization_redirect_uri")
    persona.meta["oauth"] = oauth
  end

  def build_redirect_with_params(redirect_uri, code:, state:)
    uri = URI.parse(redirect_uri)
    query_pairs = URI.decode_www_form(uri.query.to_s)
    query_pairs.reject! { |key, _value| key == "code" || key == "state" }
    query_pairs << ["code", code]
    query_pairs << ["state", state] if state.present?
    uri.query = URI.encode_www_form(query_pairs)
    uri.to_s
  end
end
