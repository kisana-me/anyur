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

    render :authorize
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
    bind_client_auth_mode(@persona, params[:code_challenge].to_s.present?)
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
      handle_generate_token()
    elsif params[:grant_type] == "refresh_token"
      handle_generate_token(is_code: false)
    else
      render json: { error: "unsupported_grant_type" }, status: 400
    end
  end



  private



  def handle_generate_token(is_code: true)
    if is_code
      return unless require_token_params(%i[client_id code redirect_uri])
    else
      return unless require_token_params(%i[client_id refresh_token])
    end

    # client/serviceを探す
    service = Service.is_normal.find_by(name_id: params[:client_id].to_s)
    unless service
      return render json: { error: "invalid_client" }, status: 400
    end

    if is_code
      # redirect_uriチェック1
      unless service.redirect_uris.include?(params[:redirect_uri])
        return render json: { error: "invalid_redirect_uri" }, status: 400
      end
    end

    # personaを探す
    if is_code
      persona = Persona.findby_token(params[:code], "authorization_code")
    else
      persona = Persona.findby_token(params[:refresh_token], "refresh_token")
    end
    unless persona
      error_code = is_code ? "invalid_code" : "invalid_refresh_token"
      return render json: { error: error_code }, status: 400
    end
    unless persona.service_id == service.id
      error_code = is_code ? "invalid_service" : "invalid_refresh_token"
      return render json: { error: error_code }, status: 400
    end
    unless client_secret_or_pkce_valid?(service, persona)
      return render json: { error: "invalid_client" }, status: 401
    end

    if is_code
      # redirect_uriチェック2
      unless authorization_redirect_uri_matches?(persona, params[:redirect_uri])
        return render json: { error: "invalid_redirect_uri" }, status: 400
      end
    end

    # token発行
    access_token = persona.generate_token(10.minutes, "access_token")
    refresh_token = persona.generate_token(30.days, "refresh_token")
    if is_code
      persona.authorization_code_expires_at = Time.current
      bind_client_auth_mode(persona, persona_challenge(persona).is_a?(Hash))
      clear_authorization_redirect_uri(persona)
      persona.with_challenge(nil, nil)
    end
    unless persona.save
      return render json: { error: "server_error" }, status: 500
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

    # 3. redirect_uri チェック
    if params[:redirect_uri].blank?
      @error = "invalid_redirect_uri"
      return
    end

    begin
      URI.parse(params[:redirect_uri])
    rescue URI::InvalidURIError, TypeError, ArgumentError
      @error = "invalid_redirect_uri"
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
    has_code_challenge = code_challenge.present?

    if has_code_challenge
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



  def client_secret_or_pkce_valid?(service, persona)
    client_secret = params[:client_secret].to_s
    if client_secret.present?
      secret_owner = Service.findby_token(client_secret, "client_secret")
      secret_owner && secret_owner.id == service.id
    else
      return false unless persona_public_client?(persona)
      verify_pkce_for_persona(persona)
    end
  end

  def require_token_params(required_keys)
    missing_keys = required_keys.filter_map do |key|
      key if params[key].blank?
    end
    return true if missing_keys.empty?

    render json: {
      error: "invalid_request",
      error_description: "missing required parameter: #{missing_keys.first}"
    }, status: 400
    false
  end

  def valid_pkce_code?(value)
    value.match?(/\A[A-Za-z0-9\-._~]{43,128}\z/)
  end

  def verify_pkce_for_persona(persona)
    challenge = persona_challenge(persona)
    return false if challenge.nil?
    return false unless challenge.is_a?(Hash)

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

  def persona_challenge(persona)
    return nil unless persona.meta.is_a?(Hash)

    persona.meta["challenge"]
  end

  def persona_oauth_meta(persona)
    return {} unless persona.meta.is_a?(Hash)

    oauth = persona.meta["oauth"]
    oauth.is_a?(Hash) ? oauth : {}
  end

  def persona_public_client?(persona)
    oauth = persona_oauth_meta(persona)
    oauth["client_auth_mode"] == "pkce"
  end

  def bind_client_auth_mode(persona, public_client)
    persona.meta = {} unless persona.meta.is_a?(Hash)
    oauth = persona_oauth_meta(persona)
    oauth["client_auth_mode"] = public_client ? "pkce" : "secret"
    persona.meta["oauth"] = oauth
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
