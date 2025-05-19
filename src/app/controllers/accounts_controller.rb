class AccountsController < ApplicationController
  before_action :signedin_account, except: :reset_password

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

  def password_edit
  end

  def password_update
    # パスワード認証
    if @current_account.authenticate(params[:account][:current_password])
      if params[:account][:password].present? && @current_account.update(account_update_password_params)
        redirect_to root_path, notice: "パスワードを更新しました"
      else
        flash.now[:alert] = "パスワードを更新できません"
        render :password_edit, status: :unprocessable_entity
      end
    else
      flash.now[:alert] = "現在のパスワードが異なります"
      render :password_edit, status: :unprocessable_entity
    end
  end

  def destroy
    @current_account.update(deleted: true)
    sign_out()
    redirect_to root_path, status: :see_other, notice: "アカウントを削除しました"
  end

  def verify_email
    if @current_account.email_verified
      redirect_to account_path, alert: "メール認証は済んでいます"
    else
      if params[:send_code] == 'true'
        if @current_account.email_locked?
          flash.now[:alert] = "メールを使用できません、お問い合わせください"
        else
          @current_account.start_EVC
          flash.now[:notice] = "認証コードを送信しました"
        end
      end
    end
  end

  def request_reset_password
  end

  def post_request_reset_password
  end

  def reset_password
  end

  def post_reset_password
  end

  def post_verify_email
    flag = (@current_account.meta['EVC_for'].to_s == 'verify_email') && (@current_account.meta['EVC'].to_s == params[:verification_code].to_s)
    if !@current_account.EVC_locked? && flag
      @current_account.email_verified = true
      @current_account.end_EVC
    elsif @current_account.EVC_locked? && flag
      flash.now[:alert] = "認証コードが無効です、再発行してください"
      render :verify_email
    else
      @current_account.fail_EVC
      flash.now[:alert] = "認証できませんでした"
      render :verify_email
    end
  end

  private

  def account_update_params
    params.expect(account: [ :name, :name_id, :email ])
  end

  def account_update_password_params
    params.expect(account: [ :password, :password_confirmation ])
  end
end
