class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  helper_method :get_tokens#kari
  before_action :current_account

  def current_account()
    @current_account = nil
    return unless token = get_tokens().first
    if account = Account.find_by_token(token)
      @current_account = account
    else
      refresh_token()
      current_account()
    end
  end

  def signed_in?
    current_account.present?
  end

  def sign_in(account)
    token = SecureRandom.urlsafe_base64
    account.remember(token)
    tokens = get_tokens()
    tokens.unshift(token)
    tokens.uniq!
    cookies.permanent.signed[:anyur] = tokens.to_json
  end

  def sign_out()
    tokens = get_tokens()
    @current_account.forget(tokens.first)
    tokens.delete(tokens.first)
    if tokens.empty?
      cookies.delete(:anyur)
    else
      cookies.permanent.signed[:anyur] = tokens.to_json
    end
    @current_account = nil
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
      cookies.permanent.signed[:anyur] = valid_tokens.to_json
    end
  end
end
