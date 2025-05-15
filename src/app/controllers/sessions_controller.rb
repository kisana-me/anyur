class SessionsController < ApplicationController
  def signin_form
    @account = Account.new
  end

  def signin
    account = Account.find_by(name_id: params[:session][:name_id], status: :normal, deleted: false)
    if account&.authenticate(params[:session][:password])
      sign_in(account)
      redirect_to root_path, notice: 'サインインしました'
    else
      @account = Account.new(name_id: params[:session][:name_id])
      @account.errors.add(:base, :invalid_singin)
      render :signin_form, status: :unprocessable_entity
    end
  end

  def signout
    sign_out if signed_in?
    redirect_to root_path, notice: 'サインアウトしました'
  end
end
