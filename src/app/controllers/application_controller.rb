class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :current_account, :signed_in?
  before_action :current_account

  def current_account
    Rails.logger.info("aaaaaaaaa")
    if session[:aid]
      @current_account ||= Account.find(session[:aid])
    elsif token = JSON.parse(cookies.signed[:anyur] || '[]').first
      if account = Account.find_by_token(token)
        sign_in(account)
        @current_account = account
      end
    end
  end

  def signed_in?
    current_account.present?
  end

  def sign_in(account)
    session[:aid] = account.id
  end

  def sign_out
    forget(@current_account)
    session.delete(:aid)
    @current_account = nil
  end

  def remember(account)
    account.remember
    tokens = Array.wrap(JSON.parse(cookies.permanent.signed[:anyur] || '[]'))
    tokens.unshift(account.remember_token)
    tokens.uniq!
    cookies.permanent.signed[:anyur] = tokens.to_json
  end

  def forget(account)
    current_token = JSON.parse(cookies.permanent.signed[:anyur] || '[]').first
    account.forget(current_token)
    tokens = Array.wrap(JSON.parse(cookies.permanent.signed[:anyur] || '[]'))
    tokens.delete(account.remember_token)
    if tokens.empty?
      cookies.delete(:anyur)
    else
      cookies.permanent.signed[:anyur] = tokens.to_json
    end
  end

end
