class Account < ApplicationRecord
  include Loggable

  has_many :sessions
  has_many :subscriptions
  has_many :activity_logs

  attribute :meta, :json, default: -> { {} }
  enum :visibility, { closed: 0, limited: 1, opened: 2 }
  enum :status, { normal: 0, locked: 1, deleted: 2 }

  before_validation :nilify_blank_attributes
  before_create :set_aid
  after_update :sync_name_with_stripe, if: :saved_change_to_name?
  after_update :sync_email_with_stripe, if: :saved_change_to_email?

  validates :name,
    presence: true,
    length: { in: 1..20, allow_blank: true }
  validates :name_id,
    presence: true,
    length: { in: 5..20, allow_blank: true },
    format: { with: NAME_ID_REGEX, message: :invalid_name_id_format, allow_blank: true },
    uniqueness: { case_sensitive: false, allow_blank: true }
  validates :description,
    allow_blank: true,
    length: { in: 1..500 }
  validates :email,
    uniqueness: { case_sensitive: false, message: :exists_email, allow_blank: true },
    length: { in: 5..120, allow_blank: true },
    format: { with: VALID_EMAIL_REGEX, message: :invalid_email_format, allow_blank: true }
  has_secure_password validations: false
  validates :password,
    allow_blank: true,
    length: { in: 8..30 },
    confirmation: true

  scope :is_normal, -> { where(status: :normal) }
  scope :isnt_deleted, -> { where.not(status: :deleted) }
  scope :is_opened, -> { where(visibility: :opened) }
  scope :isnt_closed, -> { where.not(visibility: :closed) }

  MAX_FAILED_ATTEMPTS = 7

  def email_locked?
    meta["use_email"].to_i >= 20
  end

  def active_subscription
    subscriptions
      .where(subscription_status: [ :active, :trialing ])
      .order(created_at: :desc)
      .first
  end

  def subscription_plan
    current_subscription = active_subscription()
    return :basic unless current_subscription

    return :expired unless current_subscription.current_period_end > Time.current

    case current_subscription.stripe_plan_id
    when ENV.fetch("ANYUR_PLUS_STRIPE_PRICE_ID")
      :plus
    when ENV.fetch("ANYUR_PREMIUM_STRIPE_PRICE_ID")
      :premium
    when ENV.fetch("ANYUR_LUXURY_STRIPE_PRICE_ID")
      :luxury
    else
      :unknown
    end
  end

  def admin?
    self.meta["roles"]&.include?("admin")
  end

  def self.find_by_sci(str)
    is_normal.find_by(stripe_customer_id: str)
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

  #
  # ===== BEGIN OF EMAIL FLOWS ===== #
  #

  ### EVC = Email Verification by Code # これに統一予定

  def start_EVC(evc_for: "verify_email", evc_content: "", evc_email: self.email)
    meta["use_email"] = meta["use_email"].to_i + 1 if evc_email.present?
    evc_code = "%06d" % SecureRandom.random_number(1_000_000)
    meta["EVC"] ||= {}
    meta["EVC"]["code"] = evc_code
    meta["EVC"]["for"] = evc_for
    meta["EVC"]["content"] = evc_content
    meta["EVC"]["started_at"] = Time.current
    meta["EVC"]["failed_times"] = 0
    save
    AccountMailer.authentication_code(evc_email, evc_code).deliver_now if evc_email.present?
  end

  ### change email

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

  ### reset password

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
    false
  end

  ### general methods for flows
  ### # "EVC":                      ["code", "for", "started_at", "failed_times"]
  ### # "change_email":      ["code", "next_email", "started_at", "failed_times"]
  ### # "reset_password":          ["token_digest", "started_at", "failed_times"]

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
    fails_flag && time_flag
  rescue ArgumentError, TypeError
    false
  end

  #
  # ===== END OF EMAIL FLOWS ===== #
  #

  private

  def nilify_blank_attributes
    self.email = email.presence
  end

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
