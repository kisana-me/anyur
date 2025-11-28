class AccountsController < ApplicationController
  before_action :require_signin

  def index
    @accounts = signed_in_accounts()
  end

  def change
    account_aid = params[:selected_account_aid]
    if change_account(account_aid)
      redirect_to account_path, notice: "アカウントを切り替えました"
    elsif account_aid == @current_account.aid
      redirect_to account_path, alert: "現在のアカウントです"
    else
      redirect_to account_path, alert: "アカウントを切り替えられませんでした"
    end
  end

  def show
  end

  def edit
  end

  def update
    if @current_account.update(params.expect(account: [ :name, :name_id ]))
      redirect_to account_path, notice: "更新しました"
    else
      flash.now[:alert] = "更新できませんでした"
      render :edit, status: :unprocessable_entity
    end
  end

  #
  # ===== メールアドレス変更 =====
  # メールアドレスの変更には下記が必要
  # ・現在のパスワード
  # ・新しいメールアドレスで認証コード受け取り
  #

  def edit_email
  end

  def check_email
    unless @current_account.authenticate(params.dig("account", "current_password"))
      @current_account.errors.add(:base, :wrong_current_password)
      flash.now[:alert] = "パスワードが違います"
      return render :edit_email, status: :unprocessable_entity
    end

    unless params.dig("account", "next_email") =~ VALID_EMAIL_REGEX
      @current_account.errors.add(:base, :invalid_next_email_format)
      flash.now[:alert] = "入力が正しくありません"
      return render :edit_email, status: :unprocessable_entity
    end

    if Account.exists?(email: params.dig("account", "next_email"))
      @current_account.errors.add(:base, :exists_next_email)
      flash.now[:alert] = "入力が正しくありません"
      return render :edit_email, status: :unprocessable_entity
    end

    @current_account.start_change_email(params.dig("account", "next_email"))
  end

  def update_email
    unless @current_account.flow_valid?("change_email")
      @current_account.errors.add(:base, "失敗回数が多いか時間切れです")
      flash.now[:alert] = "無効な操作です"
      return render :check_email, status: :unprocessable_entity
    end

    unless @current_account.meta.dig("change_email", "code") == params.dig("account", "authentication_code")
      @current_account.failed_flow("change_email")
      @current_account.errors.add(:base, "認証コードが異なります")
      flash.now[:alert] = "認証に失敗しました"
      return render :check_email, status: :unprocessable_entity
    end

    if @current_account.update(email: @current_account.meta.dig("change_email", "next_email"), email_verified: true)
      @current_account.end_flow("change_email")
      redirect_to account_path, notice: "メールを更新しました"
    else
      @current_account.errors.add(:base, "メールを更新できませんでした")
      flash.now[:alert] = "メールを更新できませんでした"
      render :check_email, status: :unprocessable_entity
    end
  end

  #
  # ===== パスワード変更 =====
  # 現在のパスワード入力が必須
  #

  def edit_password
  end

  def update_password
    unless @current_account.authenticate(params.dig('account', 'current_password'))
      @current_account.errors.add(:base, :wrong_current_password)
      flash.now[:alert] = "パスワードが違います"
      return render :edit_password, status: :unprocessable_entity
    end

    @current_account.assign_attributes(params.expect(account: [ :password, :password_confirmation ]))
    if @current_account.save(context: :password_save)
      redirect_to account_path, notice: "パスワードを更新しました"
    else
      flash.now[:alert] = "パスワードを更新できませんでした"
      render :edit_password, status: :unprocessable_entity
    end
  end

  def delete
  end

  def delete_confirm
    @current_account.update(status: :deleted)
    sign_out()
    redirect_to root_path, status: :see_other, notice: "アカウントを削除しました"
  end
end
