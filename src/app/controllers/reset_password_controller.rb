class ResetPasswordController < ApplicationController
  skip_before_action :require_signin

  def get_request
    @email_form = EmailForm.new()
  end

  def post_request
    @email_form = EmailForm.new(email_form_params)
    unless verify_turnstile(params["cf-turnstile-response"])
      @email_form.errors.add(:base, :failed_captcha)
      return render :get_request, status: :unprocessable_entity
    end
    return render :get_request if !@email_form.valid?
    account = Account.find_by(email: @email_form.email)
    return if !account
    return if !account.email_verified
    account.start_reset_password if account
  end

  def edit
    @account = Account.new
  end

  def update
    unless verify_turnstile(params["cf-turnstile-response"])
      @account = Account.new()
      @account.errors.add(:base, :failed_captcha)
      return render :edit, status: :unprocessable_entity
    end
    @account = Account.find_by(email: params.dig(:account, :email))
    if @account && @account.flow_valid?("reset_password") && @account.authenticate_reset_password(params[:account][:reset_password_token])
      @account.check_password = true
      if @account.update(account_update_password_params)
        @account.end_flow("reset_password")
        return redirect_to root_path, notice: "パスワードを更新しました"
      end
    else
      @account = Account.new()
      @account.errors.add(:base, "無効です")
    end
    render :edit, status: :unprocessable_entity
  end

  private

  def email_form_params
    params.expect(email_form: [ :email ])
  end

  def account_update_password_params
    params.expect(account: [ :password, :password_confirmation ])
  end
end
