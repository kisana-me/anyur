class SignupController < ApplicationController

  # アカウント作成

  def index
  end

  def form_1
    @account = Account.new()
  end

  def check_1
    @account = Account.new(account_params)
    @account.validate_level_1 = true
    if @account.valid?(:level1)
      session[:new_account] ||= {}
      session[:new_account].merge!(
        name: params[:account][:name],
        name_id: params[:account][:name_id],
        password: params[:account][:password]
      )
      redirect_to signup_form_confirm_path
    else
      render :form_1
    end
  end

  def form_confirm
    @account = Account.new(session[:new_account])
  end

  def check_confirm
    @account = Account.new(session[:new_account].to_h.merge(account_params))
    if @account.save
      session.delete(:new_account)
      redirect_to @account, notice: "アカウントを作成しました"
    else
      render :form_confirm, status: :unprocessable_entity
    end
  end

  private

  def account_params
    params.expect(account: [ :name, :name_id, :email, :password, :password_confirmation ])
  end
end
