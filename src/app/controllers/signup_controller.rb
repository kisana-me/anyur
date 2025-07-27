class SignupController < ApplicationController
  skip_before_action :require_signin

  # アカウント作成

  def index
    @account = Account.new(session[:new_account] || {})
  end

  def page_1
    @account = Account.new(account_params)
    unless verify_turnstile(params["cf-turnstile-response"])
      @account.errors.add(:base, :failed_captcha)
      return render :index, status: :unprocessable_entity
    end
    unless @account.terms_agreed
      @account.errors.add(:base, :require_agreed)
      return render :index, status: :unprocessable_entity
    end
    if @account.valid?()
      session[:new_account] ||= {}
      session[:new_account].merge!(
        name: params[:account][:name],
        name_id: params[:account][:name_id],
        email: params[:account][:email],
        terms_agreed: params[:account][:terms_agreed],
        password: params[:account][:password]
      )
    else
      render :index
    end
  end

  def page_2
    @account = Account.new(session[:new_account].to_h.merge(account_params))
    unless verify_turnstile(params["cf-turnstile-response"])
      @account.errors.add(:base, :failed_captcha)
      return render :page_1, status: :unprocessable_entity
    end
    unless @account.terms_agreed
      @account.errors.add(:base, :require_agreed)
      return render :page_1, status: :unprocessable_entity
    end
    if @account.save
      session.delete(:new_account)
      sign_in(@account)
      @current_account = @account
      flash.now[:notice] = "アカウントを作成しました"
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
        :terms_agreed,
        :password,
        :password_confirmation
      ]
    )
  end
end
