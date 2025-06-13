class ApplicationController < ActionController::Base
  include SessionManagement
  include TurnstileManagement

  before_action :current_account
  before_action :require_signin
  before_action :set_current_attributes

  helper_method :email_verified?, :admin?

  unless Rails.env.development?
    rescue_from Exception,                      with: :render_500
    rescue_from ActiveRecord::RecordNotFound,   with: :render_404
    rescue_from ActionController::RoutingError, with: :render_404
  end

  # error page

  def render_400
    render "errors/400", status: :bad_request
  end

  def render_404
    render "errors/404", status: :not_found
  end

  def render_500
    render "errors/500", status: :internal_server_error
  end

  # general method

  def require_signin
    if @current_account&.email_verified
    elsif @current_account
      session[:email_verified_return_to] = request.fullpath
      redirect_to verify_email_path, alert: "メール認証してください"
    else
      session[:signin_return_to] = request.fullpath
      redirect_to signin_path, alert: "サインインしてください"
    end
  end

  def require_admin
    unless admin?
      render_404
    end
  end

  def email_verified?
    @current_account&.email_verified
  end

  def admin?
    @current_account&.admin?
  end

  private

  def set_current_attributes
    Current.account = @current_account
    Current.ip_address = request.remote_ip
    Current.user_agent = request.user_agent
  end
end
