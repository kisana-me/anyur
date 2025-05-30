class AccountsController < ApplicationController

  def index
    tokens = get_tokens()
    @accounts = Account.signed_in_accounts(tokens)
  end

  def change
    account_id = params[:selected_account_id]
    if change_account(account_id)
      redirect_to account_path, notice: "アカウントを切り替えました"
    else
      redirect_to account_path, alert: "アカウントを切り替えられませんでした"
    end
  end

  def show
  end

  def edit
  end

  def update
    if @current_account.update(account_update_params)
      redirect_to account_path, notice: "更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def edit_email
    @ep_form = EmailPasswordForm.new()
  end

  def check_email
    @ep_form = EmailPasswordForm.new(params.expect(email_password_form: [ :password, :email ]))
    unless @current_account.authenticate(@ep_form.password)
      @ep_form.errors.add(:password, :wrong_password)
      return render :edit_email, status: :unprocessable_entity
    end
    return render :edit_email if !@ep_form.valid?
    @current_account.start_change_email(@ep_form.email)
  end

  def update_email
    @ep_form = EmailPasswordForm.new()
    if @current_account.flow_valid?("change_email")
      if @current_account.meta.dig("change_email", "code") == params.dig("email_password_form", "authentication_code")
        if @current_account.update(email: @current_account.meta.dig("change_email", "next_email"))
          @current_account.end_flow("change_email")
          return redirect_to account_path, notice: "メールを更新しました"
        else
          @ep_form.errors.add(:base, "メールを更新できませんでした")
          render :check_email, alert: "メールを更新できませんでした"
        end
      else
      failed_flow("change_email")
      @ep_form.errors.add(:base, "認証失敗")
      render :check_email, alert: "認証失敗"
      end
    else
      @ep_form.errors.add(:base, "無効")
      render :check_email, alert: "無効"
    end
  end

  def edit_password
    if @current_account.email_verified
      @current_account.start_EVC(evc_for: "change_password")
      flash.now[:notice] = "認証コードを送信しました"
    end
    @account = Account.new
  end

  def update_password
    flag = (@current_account.meta.dig("EVC", "for").to_s == "change_password") && (@current_account.meta.dig("EVC", "code").to_s == params.dig("account", "verification_code").to_s)
    if @current_account.flow_valid?("EVC") && flag
      # 次へ進む
    elsif !@current_account.flow_valid?("EVC") && flag
      @current_account.errors.add(:base, "認証コードが無効です、再発行してください")
      return render :edit_password
    else
      @current_account.errors.add(:base, "認証できませんでした")
      return render :edit_password
    end

    @current_account.check_password = true
    if @current_account.update(account_update_password_params)
      @current_account.end_flow("EVC")
      return redirect_to account_path, notice: "パスワードを更新しました"
    else
      render :edit_password, status: :unprocessable_entity
    end
  end

  def delete
  end

  def delete_confirm
    @current_account.update(deleted: true)
    sign_out()
    redirect_to root_path, status: :see_other, notice: "アカウントを削除しました"
  end

  private

  def account_update_params
    params.expect(account: [ :name, :name_id ])
  end

  def account_update_email_params
    params.expect(account: [ :email ])
  end

  def account_update_password_params
    params.expect(account: [ :password, :password_confirmation ])
  end

  def email_form_params
    params.expect(email_form: [ :email ])
  end
end
