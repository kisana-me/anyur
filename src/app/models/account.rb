class Account < ApplicationRecord
  self.primary_key = "id"
  has_many :sessions
  attribute :cache, :json, default: {}
  attribute :meta, :json, default: {}
  attribute :settings, :json, default: {}
  enum :status, { normal: 0, locked: 1, suspended: 2, hibernated: 3, frozen: 4 }, prefix: true

  before_create :generate_custom_id
  # before_update :reset_email_verified_if_email_changed

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

  def authenticated?(token)
    lookup = Digest::SHA256.hexdigest(token)[0...24]
    return false unless ses = Session.find_by(id: lookup, deleted: false)
    BCrypt::Password.new(ses.remember_token).is_password?(token)
  end

  def remember(token, ip, ua)
    lookup = Digest::SHA256.hexdigest(token)[0...24]
    Session.create(id: lookup, account: self, token_digest: generate_digest(token), ip_address: ip, user_agent: ua)
  end

  def forget(token)
    lookup = Digest::SHA256.hexdigest(token)[0...24]
    return unless ses = Session.find_by(id: lookup, deleted: false)
    ses.update(deleted: true)
  end

  def email_locked?
    meta["use_email"].to_i >= 20
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
    token = generate_base36(32)
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

  def self.find_by_token(token)
    lookup = Digest::SHA256.hexdigest(token)[0...24]
    account = Session.find_by(id: lookup, deleted: false)&.account
    account&.status_normal? && !account.deleted ? account : nil
  end

  def self.signed_in_accounts(tokens)
    tokens.map { |t| Account.find_by_token(t) }.compact.uniq
  end

  private

  # def reset_email_verified_if_email_changed
  #   if will_save_change_to_email?
  #     self.email_verified = false
  #   end
  # end
end
