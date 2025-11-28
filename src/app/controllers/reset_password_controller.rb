class ResetPasswordController < ApplicationController
  def get_request
    @account = Account.new()
  end

  def post_request
    @account = Account.new(params.expect(account: :email))

    unless verify_turnstile(params["cf-turnstile-response"])
      @account.errors.add(:base, :failed_captcha)
      return render :get_request, status: :unprocessable_entity
    end

    unless @account.email =~ VALID_EMAIL_REGEX
      @account.errors.add(:email, :invalid_email_format)
      return render :get_request, status: :unprocessable_entity
    end

    account = Account
      .is_normal
      .find_by(email: @account.email, email_verified: true)

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

    @account = Account
      .is_normal
      .find_by(email: params.dig(:account, :email), email_verified: true)

    if @account && @account.flow_valid?("reset_password") && @account.authenticate_reset_password(params[:account][:reset_password_token])
      @account.assign_attributes(account_update_password_params)
      if @account.save(context: :password_save)
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

  def account_update_password_params
    params.expect(account: [ :password, :password_confirmation ])
  end
end
