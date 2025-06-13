class Account < ApplicationRecord
  has_many :sessions
  has_many :subscriptions
  has_many :activity_logs
  attribute :cache, :json, default: {}
  attribute :meta, :json, default: {}
  attribute :settings, :json, default: {}
  enum :status, { normal: 0, locked: 1 }, prefix: true

  before_create :set_aid
  # after_update :log_changes
  after_update :sync_name_with_stripe, if: :saved_change_to_name?
  after_update :sync_email_with_stripe, if: :saved_change_to_email?

  attr_accessor :check_password

  validates :name, presence: true
  validates :name, length: { in: 1..20 },
                    if: -> { name.present? }
  validates :name_id, presence: true
  validates :name_id, uniqueness: { case_sensitive: false },
                      length: { in: 5..20 },
                      format: { with: NAME_ID_REGEX, message: :invalid_name_id_format },
                      if: -> { name_id.present? }
  validates :email, presence: true
  validates :email, uniqueness: { case_sensitive: false, message: :exists_email },
                    length: { in: 5..120 },
                    format: { with: VALID_EMAIL_REGEX, message: :invalid_email_format },
                    if: -> { email.present? }
  has_secure_password
  validates :password, presence: true,
                        if: :check_password
  validates :password, length: { in: 8..30 },
                        if: -> { password.present? }
  validates :password, confirmation: true,
                        if: -> { password_confirmation.present? }
  validates :password_confirmation, presence: true,
                                    if: -> { password.present? && password_confirmation.present? }

  MAX_FAILED_ATTEMPTS = 7

  def email_locked?
    meta["use_email"].to_i >= 20
  end

  def active_subscription
    subscriptions.where(status: [:active, :trialing])
                 .order(created_at: :desc)
                 .first
  end

  def self.find_by_sci(str)
    find_by(stripe_customer_id: str, status: :normal, deleted: false)
  end

  # check signin fails

  def fail_signin
    next_failed_signin = meta["failed_signin"].to_i + 1
    if next_failed_signin >= MAX_FAILED_ATTEMPTS
      meta["lock_signin_at"] = Time.current
    end
    meta["failed_signin"] = next_failed_signin
    save
  end

  def reset_failed_signin
    meta.delete("failed_signin")
    meta.delete("lock_signin_at")
    save
  end

  def signin_locked?
    meta["failed_signin"].to_i >= MAX_FAILED_ATTEMPTS
  end

  # EVC = Email Verification by Code

  def start_EVC(send_email: true, evc_for: "verify_email")
    meta["use_email"] = meta["use_email"].to_i + 1 if send_email
    code = "%06d" % SecureRandom.random_number(1_000_000)
    meta["EVC"] ||= {}
    meta["EVC"]["code"] = code
    meta["EVC"]["for"] = evc_for
    meta["EVC"]["started_at"] = Time.current
    meta["EVC"]["failed_times"] = 0
    save
    AccountMailer.authentication_code(self.email, code).deliver_now if send_email
  end

  # change email

  def start_change_email(next_email)
    meta["use_email"] = meta["use_email"].to_i + 1
    code = "%06d" % SecureRandom.random_number(1_000_000)
    meta["change_email"] ||= {}
    meta["change_email"]["code"] = code
    meta["change_email"]["next_email"] = next_email
    meta["change_email"]["started_at"] = Time.current
    meta["change_email"]["failed_times"] = 0
    save
    AccountMailer.authentication_code(next_email, code).deliver_now
  end

  # reset password

  def start_reset_password
    meta["use_email"] = meta["use_email"].to_i + 1
    token = SecureRandom.base36(32)
    meta["reset_password"] ||= {}
    meta["reset_password"]["token_digest"] = generate_digest(token)
    meta["reset_password"]["started_at"] = Time.current
    meta["reset_password"]["failed_times"] = 0
    save
    AccountMailer.password_reset(self.email, token).deliver_now
  end

  def authenticate_reset_password(token)
    token_digest = meta.dig("reset_password", "token_digest")
    if BCrypt::Password.new(token_digest).is_password?(token)
      return true
    else
      failed_flow("reset_password")
    end
    return false
  end

  # flow

  def start_flow(str)
  end

  def end_flow(str)
    meta.delete(str)
    save
  end

  def failed_flow(str)
    next_failed_times = meta.dig(str, "failed_times").to_i + 1
    meta[str]["failed_times"] = next_failed_times
    save
  end

  def flow_valid?(str, int = 10)
    fails_flag = meta.dig(str, "failed_times").to_i < MAX_FAILED_ATTEMPTS
    time_flag = Time.current < Time.parse(meta.dig(str, "started_at").to_s) + int.minutes
    return fails_flag && time_flag
  rescue ArgumentError, TypeError
    false
  end

  # ===== #

  def admin?
    self.roles.include?("admin")
  end

  private

  def sync_name_with_stripe
    return if stripe_customer_id.blank?

    begin
      # 高頻度の更新が予想される場合、API呼び出しの頻度を考慮
      # 場合によっては非同期処理 (バックグラウンドジョブ) で行うことを検討
      Stripe::Customer.update(
        stripe_customer_id,
        { name: name } # 更新後の名前
      )
      Rails.logger.info "Stripe customer name updated for account #{id}"
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe API error while updating customer name for account #{id}: #{e.message}"
      # エラーハンドリング
    end
  end

  def sync_email_with_stripe
    return if stripe_customer_id.blank? # Stripe顧客IDがない場合は何もしない

    begin
      Stripe::Customer.update(
        stripe_customer_id,
        { email: email } # 更新後のメールアドレス
      )
      Rails.logger.info "Stripe customer email updated for account #{id}"
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe API error while updating customer email for account #{id}: #{e.message}"
      # エラーハンドリング (例: あとで再試行するジョブをキューに入れるなど)
    end
  end
end
