class SignupController < ApplicationController

  # アカウント作成

  def index
    @account = Account.new(session[:new_account] || {})
  end

  def page_1
    @account = Account.new(account_params)
    @account.validate_level_1 = true
    if @account.valid?(:level1)
      session[:new_account] ||= {}
      session[:new_account].merge!(
        name: params[:account][:name],
        name_id: params[:account][:name_id],
        email: params[:account][:email],
        password: params[:account][:password]
      )
    else
      render :index
    end
  end

  def page_2
    @account = Account.new(session[:new_account].to_h.merge(account_params))
    if @account.save
      session.delete(:new_account)
      sign_in(@account)
      flash.now[:notice] = 'アカウントを作成しました'
    else
      render :page_1, status: :unprocessable_entity
    end
  end

  private

  def account_params
    params.expect(account: [ :name, :name_id, :email, :password, :password_confirmation ])
  end
end
