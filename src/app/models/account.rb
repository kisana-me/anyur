class Account < ApplicationRecord
  self.primary_key = 'id'
  has_many :sessions
  enum :status, { normal: 0, locked: 1, suspended: 2, hibernated: 3, frozen: 4 }, prefix: true

  before_create :generate_custom_id

  attr_accessor :validate_level_1

  validates :name, presence: true
  validates :name, length: { in: 1..20 },
                    if: -> { name.present? }
  validates :name_id, presence: true
  validates :name_id, uniqueness: { case_sensitive: false },
                      length: { in: 5..20 },
                      format: { with: /\A[a-zA-Z0-9_-]+\z/, message: :invalid_name_id_format },
                      if: -> { name_id.present? }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  validates :email, uniqueness: { case_sensitive: false },
                    length: { in: 5..120 },
                    format: { with: VALID_EMAIL_REGEX, message: :invalid_email_format },
                    allow_blank: true,
                    unless: :validate_level_1
  has_secure_password
  validates :password, length: { in: 8..30 },
                        if: -> { password.present? }
  validates :password, confirmation: true,
                        if: -> { password_confirmation.present? },
                        unless: :validate_level_1
  validates :password_confirmation, presence: true,
                                    if: -> { password.present? && password_confirmation.present? },
                                    unless: :validate_level_1

  def self.digest(token)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST : BCrypt::Engine.cost
    BCrypt::Password.create(token, cost: cost)
  end

  def authenticated?(token)
    lookup = Digest::SHA256.hexdigest(token)[0...24]
    return false unless ses = Session.find_by(id: lookup, deleted: false)
    BCrypt::Password.new(ses.remember_token).is_password?(token)
  end

  def remember(token)
    lookup = Digest::SHA256.hexdigest(token)[0...24]
    Session.create(id: lookup, account: self, token_digest: Account.digest(token))
  end

  def forget(token)
    lookup = Digest::SHA256.hexdigest(token)[0...24]
    return unless ses = Session.find_by(id: lookup, deleted: false)
    ses.update(deleted: true)
  end

  def self.find_by_token(token)
    lookup = Digest::SHA256.hexdigest(token)[0...24]
    account = Session.find_by(id: lookup, deleted: false)&.account
    account&.status_normal? && !account.deleted ? account : nil
  end

  def self.signed_in_accounts(tokens)
    tokens.map { |t| Account.find_by_token(t) }.compact.uniq
  end
end
