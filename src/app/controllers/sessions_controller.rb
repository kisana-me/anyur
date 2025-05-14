class SessionsController < ApplicationController
  def signin_form
  end

  def signin
    account = Account.find_by(name_id: params[:name_id])
    if account&.authenticate(params[:password])
      sign_in(account)
      params[:remember_me] == "1" ? remember(account) : forget(account)
      redirect_to root_path, notice: 'ログイン成功'
    else
      flash.now[:alert] = 'ログインできませんでした'
      render :signin_form
    end
  end

  def signout
    sign_out if signed_in?
    redirect_to root_path, notice: 'ログアウトしました'
  end
end
