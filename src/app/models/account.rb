class Account < ApplicationRecord
  self.primary_key = "id"
  has_many :sessions
  attribute :cache, :json, default: {}
  attribute :meta, :json, default: {}
  attribute :settings, :json, default: {}
  enum :status, { normal: 0, locked: 1, suspended: 2, hibernated: 3, frozen: 4 }, prefix: true

  before_create :generate_custom_id
  before_update :reset_email_verified_if_email_changed

  attr_accessor :validate_level_1

  validates :name, presence: true
  validates :name, length: { in: 1..20 },
                    if: -> { name.present? }
  validates :name_id, presence: true
  validates :name_id, uniqueness: { case_sensitive: false },
                      length: { in: 5..20 },
                      format: { with: NAME_ID_REGEX, message: :invalid_name_id_format },
                      if: -> { name_id.present? }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  validates :email, presence: true
  validates :email, uniqueness: { case_sensitive: false, message: :exists_email },
                    length: { in: 5..120 },
                    format: { with: VALID_EMAIL_REGEX, message: :invalid_email_format },
                    if: -> { email.present? }
  has_secure_password
  validates :password, length: { in: 8..30 },
                        if: -> { password.present? }
  validates :password, confirmation: true,
                        if: -> { password_confirmation.present? },
                        unless: :validate_level_1
  validates :password_confirmation, presence: true,
                                    if: -> { password.present? && password_confirmation.present? },
                                    unless: :validate_level_1

  MAX_FAILED_ATTEMPTS = 7

  def self.digest(token)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST : BCrypt::Engine.cost
    BCrypt::Password.create(token, cost: cost)
  end

  def authenticated?(token)
    lookup = Digest::SHA256.hexdigest(token)[0...24]
    return false unless ses = Session.find_by(id: lookup, deleted: false)
    BCrypt::Password.new(ses.remember_token).is_password?(token)
  end

  def remember(token, ip, ua)
    lookup = Digest::SHA256.hexdigest(token)[0...24]
    Session.create(id: lookup, account: self, token_digest: Account.digest(token), ip_address: ip, user_agent: ua)
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
    meta["EVC"] = code
    meta["EVC_for"] = evc_for
    meta["start_EVC_at"] = Time.current
    meta.delete("lock_EVC_at")
    meta.delete("failed_EVC")
    save
    AccountMailer.authentication_code(self, code).deliver_now if send_email
  end

  def fail_EVC
    next_failed_EVC = meta["failed_EVC"].to_i + 1
    if next_failed_EVC >= MAX_FAILED_ATTEMPTS
      meta["lock_EVC_at"] = Time.current
    end
    meta["failed_EVC"] = next_failed_EVC
    save
  end

  def end_EVC
    meta.delete("EVC")
    meta.delete("EVC_for")
    meta.delete("start_EVC_at")
    meta.delete("lock_EVC_at")
    meta.delete("failed_EVC")
    save
  end

  def EVC_locked?
    fails_flag = meta["failed_EVC"].to_i >= MAX_FAILED_ATTEMPTS
    start_at = meta["start_EVC_at"]
    time_flag = true
    if start_at.present?
      time_flag = Time.current >= Time.parse(start_at.to_s) + 3.minutes
    end
    return fails_flag || time_flag
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

  def reset_email_verified_if_email_changed
    if will_save_change_to_email?
      self.email_verified = false
    end
  end
end
