class AccountsController < ApplicationController
  before_action :set_account, only: %i[ show ]
  before_action :set_current_account, only: %i[ edit update destroy ]

  def show
  end

  def edit
  end

  def update
    if @account.update(account_params)
      redirect_to @account, notice: "Account was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @account.update(deleted: true)
    # signout
    redirect_to accounts_path, status: :see_other, notice: "Account was successfully destroyed."
  end

  private

  def set_account
    @account = Account.find(params.expect(:id))
  end
  
  def set_current_account
    @account = Account.find(params.expect(:id))
  end

  def account_params
    params.expect(account: [ :name, :name_id, :password, :password_confirmation ])
  end
end
