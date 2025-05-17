class AccountsController < ApplicationController
  before_action :signedin_account

  def index
    tokens = get_tokens()
    @accounts = Account.signed_in_accounts(tokens)
  end

  def change
    account_id = params[:selected_account_id]
    if change_account(account_id)
      redirect_to accounts_path, notice: "アカウントを切り替えました"
    else
      redirect_to accounts_path, alert: "アカウントを切り替えられませんでした"
    end
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

  def account_update_params
    params.expect(account: [ :name, :name_id, :email ])
  end

  def account_update_password_params
    params.expect(account: [ :password, :password_confirmation ])
  end
end
