class ApplicationController < ActionController::Base
  require 'net/http'
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :current_account
  helper_method :admin?

  # before action

  def signedin_account
    unless @current_account
      redirect_to signin_path, alert: 'サインインしてください'
    end
  end

  def email_verified_account
    unless @current_account&.email_verified
      redirect_to account_path, alert: 'メール認証してください'
    end
  end

  def admin_account
    unless admin?
      render_404
    end
  end

  # error page

  def render_400
    render 'errors/400', status: :bad_request
  end

  def render_404
    render 'errors/404', status: :not_found
  end

  def render_500
    render 'errors/500', status: :internal_server_error
  end

  # general method

  def current_account
    @current_account = nil
    return unless token = get_tokens().first
    if account = Account.find_by_token(token)
      @current_account = account
    else
      refresh_token
      current_account
    end
  end

  def signed_in?
    @current_account.present?
  end

  def admin?
    signed_in? && @current_account.admin?
  end

  def verify_turnstile(token)
    return true if Rails.env.development?
    uri = URI("https://challenges.cloudflare.com/turnstile/v0/siteverify")
    res = Net::HTTP.post_form(uri, {
      "secret" => ENV['CLOUDFLARE_TURNSTILE_SECRET_KEY'],
      "response" => token,
      "remoteip" => request.remote_ip
    })
    result = JSON.parse(res.body)
    result["success"] == true
  end

  # signin session

  def sign_in(account)
    token = SecureRandom.urlsafe_base64
    account.remember(token, request.remote_ip, request.user_agent)
    tokens = get_tokens()
    tokens.unshift(token)
    tokens.uniq!
    write_tokens(tokens)
  end

  def sign_out()
    tokens = get_tokens()
    @current_account.forget(tokens.first)
    tokens.delete(tokens.first)
    if tokens.empty?
      cookies.delete(:anyur)
    else
      write_tokens(tokens)
    end
    @current_account = nil
  end

  def change_account(account_id)
    tokens = get_tokens()
    scope_token = ''
    tokens.each do |t|
      if account_id == Account.find_by_token(t)&.id
        scope_token = t
        break
      end
    end
    if scope_token.present?
      new_tokens = tokens.partition { |t| t == scope_token }.flatten
      write_tokens(new_tokens)
      return true
    else
      return false
    end
  end

  def get_tokens()
    Array.wrap(JSON.parse(cookies.permanent.signed[:anyur] || '[]'))
  end

  def refresh_token()
    tokens = get_tokens()
    valid_tokens = tokens.select { |token| Account.find_by_token(token).present? }
    if valid_tokens.empty?
      cookies.delete(:anyur)
    else
      write_tokens(valid_tokens)
    end
  end

  def write_tokens(tokens)
    cookies.signed[:anyur] = {
      value: tokens.to_json,
      domain: :all,
      tld_length: 3,
      same_site: :strict,
      expires: 1.year.from_now,
      secure: Rails.env.production?,
      httponly: true
    }
  end
end
