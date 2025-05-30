class VerifyEmailController < ApplicationController
  skip_before_action :require_signin
  before_action :require_signin_without_email_verified

  def index
  end

  def change
  end

  def post_change
    if @current_account.update(change_email_params)
      redirect_to verify_email_path, notice: "メールを更新しました"
    else
      render :change, status: :unprocessable_entity
    end
  end

  def code
    if params[:send_code] == "true"
      if @current_account.email_locked?
        flash.now[:alert] = "メールを使用できません、お問い合わせください"
      else
        @current_account.start_EVC
        flash.now[:notice] = "認証コードを送信しました"
      end
    end
  end

  def post_code
    flag = (@current_account.meta.dig("EVC", "for").to_s == "verify_email") && (@current_account.meta.dig("EVC", "code").to_s == params[:verification_code].to_s)
    if @current_account.flow_valid?("EVC") && flag
      @current_account.email_verified = true
      @current_account.end_flow("EVC")
      render :complete
    elsif !@current_account.flow_valid?("EVC") && flag
      flash.now[:alert] = "認証コードが無効です、再発行してください"
      render :code
    else
      @current_account.failed_flow("EVC")
      flash.now[:alert] = "認証できませんでした"
      render :code
    end
  end

  private

  def require_signin_without_email_verified
    if @current_account&.email_verified
      redirect_to account_path, alert: "メール認証済みです"
    elsif @current_account
    else
      redirect_to signin_path, alert: "サインインしてください"
    end
  end

  def change_email_params
    params.expect(account: [ :email ])
  end
end
