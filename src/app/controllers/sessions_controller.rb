class SessionsController < ApplicationController
  def signin
    @account = Account.new
  end

  def post_signin
    @account = Account.new(name_id: params[:session][:name_id], password: params[:session][:password])
    unless verify_turnstile(params["cf-turnstile-response"])
      @account.errors.add(:base, :failed_captcha)
      return render :signin, status: :unprocessable_entity
    end
    account = Account.find_by(name_id: params[:session][:name_id], status: :normal, deleted: false)
    if !account&.signin_locked? && account&.authenticate(params[:session][:password])
      sign_in(account)
      account.reset_failed_signin
      redirect_to home_path, notice: 'サインインしました'
    elsif account&.signin_locked? && account&.authenticate(params[:session][:password])
      @account.errors.add(:base, :singin_locked)
      render :signin, status: :unprocessable_entity
    else
      account.fail_signin if account
      @account.errors.add(:base, :invalid_singin)
      render :signin, status: :unprocessable_entity
    end
  end

  def signout
    sign_out if signed_in?
    redirect_to root_path, notice: 'サインアウトしました'
  end
end
