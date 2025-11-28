class ApplicationController < ActionController::Base
  include ErrorsManagement
  include SessionManagement
  include TurnstileManagement

  before_action :current_account
  before_action :set_current_attributes

  helper_method :email_verified?, :admin?

  def routing_error
    raise ActionController::RoutingError, params[:path]
  end

  private

  def require_signin
    return if @current_account
    store_location
    redirect_to signin_path, alert: "サインインしてください"
  end

  def require_admin
    render_404 unless admin?
  end

  def email_verified?
    @current_account&.email_verified
  end

  def admin?
    @current_account&.admin?
  end

  def store_location
    session[:forwarding_url] = request.original_url if request.get?
  end

  def redirect_back_or(default = root_path, **options)
    redirect_to(session.delete(:forwarding_url) || default, **options)
  end

  def set_current_attributes
    Current.account = @current_account
    Current.ip = request.remote_ip
    Current.user_agent = request.user_agent
  end
end
