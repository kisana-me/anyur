class SignupController < ApplicationController

  # アカウント作成

  def index
    @account = Account.new(session[:signup_account_params] || {})
  end

  def page_1
    @account = Account.new(account_params)
    unless verify_turnstile(params["cf-turnstile-response"])
      @account.errors.add(:base, :failed_captcha)
      return render :index, status: :unprocessable_entity
    end
    unless params[:account][:terms_agreed] == "1"
      @account.errors.add(:base, :require_agreed)
      return render :index, status: :unprocessable_entity
    end
    unless @account.valid?(:password_save)
      return render :index, status: :unprocessable_entity
    end
    session[:signup_account_params] = account_params.except("password_confirmation")
  end

  def page_2
    @account = Account.new((session[:signup_account_params] || {}).merge(account_params.slice("password_confirmation")))
    unless verify_turnstile(params["cf-turnstile-response"])
      @account.errors.add(:base, :failed_captcha)
      return render :page_1, status: :unprocessable_entity
    end
    if @account.save(context: :password_save)
      session.delete(:signup_account_params)
      sign_in(@account)
      flash[:notice] = "アカウントを作成しました"
      if session[:forwarding_url]
        redirect_to session.delete(:forwarding_url)
      else
        redirect_to account_path
      end
    else
      render :page_1, status: :unprocessable_entity
    end
  end

  private

  def account_params
    params.expect(
      account: [
        :name,
        :name_id,
        :email,
        :password,
        :password_confirmation
      ]
    )
  end
end
