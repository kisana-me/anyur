class AccountsController < ApplicationController
  before_action :signedin_account#, except: :reset_password

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
    if @current_account.email_verified
      @current_account.start_change_email(@ep_form.email)
    else
      if @current_account.update(email: @ep_form.email)
        return redirect_to account_path, notice: "メールを更新しました"
      else
        render :edit_email, status: :unprocessable_entity
      end
    end
  end

  def update_email
    @ep_form = EmailPasswordForm.new()
    return redirect_to account_path, notice: "メールは認証済みです" if !@current_account.email_verified
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

    # @account = Account.new(
    #   email: params[:account][:email],
    #   password: params[:account][:password]
    # )
    # unless @current_account.authenticate(params[:account][:password])
    #   @current_account.errors.add(:base, :wrong_password)
    #   return render :edit_email, status: :unprocessable_entity
    # end
    # if params[:account][:email].present? && @current_account.update(account_update_email_params)
    #   # 変更適用メールを送信して、それを踏んでもらえたら適用が望ましい
    #   return redirect_to account_path, notice: "メールを更新しました"
    # elsif params[:account][:email].blank?
    #   @current_account.errors.add(:email, :blank)
    # end
    # render :edit_email, status: :unprocessable_entity
  end

  def edit_password
    if @current_account.email_verified
      @current_account.start_EVC(evc_for: "change_password")
      flash.now[:notice] = "認証コードを送信しました"
    end
    @account = Account.new
  end

  def update_password
    if @current_account.email_verified
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
    else
      if @current_account.authenticate(params[:account][:current_password])
        # 次へ進む
      else
        @current_account.errors.add(:base, :wrong_password)
        return render :edit_password
      end
    end

    @current_account.check_password = true
    if @current_account.update(account_update_password_params)
      @current_account.end_flow("EVC")
      return redirect_to account_path, notice: "パスワードを更新しました"
    else
      render :edit_password, status: :unprocessable_entity
    end
  end

  def verify_email
    if @current_account.email_verified
      redirect_to account_path, alert: "メール認証は済んでいます"
    else
      if params[:send_code] == "true"
        if @current_account.email_locked?
          flash.now[:alert] = "メールを使用できません、お問い合わせください"
        else
          @current_account.start_EVC
          flash.now[:notice] = "認証コードを送信しました"
        end
      end
    end
  end

  def post_verify_email
    flag = (@current_account.meta.dig("EVC", "for").to_s == "verify_email") && (@current_account.meta.dig("EVC", "code").to_s == params[:verification_code].to_s)
    if @current_account.flow_valid?("EVC") && flag
      @current_account.email_verified = true
      @current_account.end_flow("EVC")
      redirect_to account_path, notice: "認証が完了しました"
    elsif !@current_account.flow_valid?("EVC") && flag
      flash.now[:alert] = "認証コードが無効です、再発行してください"
      render :verify_email
    else
      @current_account.failed_flow("EVC")
      flash.now[:alert] = "認証できませんでした"
      render :verify_email
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
