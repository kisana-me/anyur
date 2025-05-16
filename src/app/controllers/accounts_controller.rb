class AccountsController < ApplicationController
  # before_action :set_account, only: %i[ show ]

  def index
    tokens = get_tokens()
    @accounts = Account.signed_in_accounts(tokens)
  end

  def show
  end

  def edit
  end

  def update
    if @current_account.update(account_update_params)
      redirect_to root_path, notice: "更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @current_account.update(deleted: true)
    sign_out()
    redirect_to root_path, status: :see_other, notice: "アカウントを削除しました"
  end

  private

  def account_params
    params.expect(account: [ :name, :name_id, :email, :password, :password_confirmation ])
  end

  def account_update_params
    params.expect(account: [ :name, :name_id, :email ])
  end
end
