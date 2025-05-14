class Account < ApplicationRecord
  self.primary_key = 'id'
  has_many :sessions
  attr_accessor :validate_level_1

  validates :name, presence: true
  validates :name, length: { in: 1..20 },
                    if: -> { name.present? }
  validates :name_id, presence: true
  validates :name_id, uniqueness: { case_sensitive: false },
                      length: { in: 5..20 },
                      format: { with: /\A[a-z0-9]+\z/ },
                      if: -> { name_id.present? }
  validates :email, uniqueness: { case_sensitive: false },
                    length: { in: 5..120 },
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    allow_blank: true,
                    unless: :validate_level_1
  has_secure_password
  validates :password, length: { in: 8..30 },
                        if: -> { password.present? }
  validates :password, confirmation: true,
                        if: -> { password_confirmation.present? },
                        unless: :validate_level_1
  validates :password_confirmation, presence: true,
                                    if: -> { password.present? },
                                    unless: :validate_level_1

  before_create :generate_custom_id

  attr_accessor :remember_token

  def self.digest(token)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST : BCrypt::Engine.cost
    BCrypt::Password.create(token, cost: cost)
  end

  def remember
    self.remember_token = SecureRandom.urlsafe_base64
    lookup = Digest::SHA256.hexdigest(remember_token)[0...24]
    Session.create(id: lookup, account: self, token_digest: Account.digest(remember_token))
  end

  def authenticated?(token)
    lookup = Digest::SHA256.hexdigest(token)[0...24]
    return false unless ses = Session.find_by(id: lookup, deleted: false)
    BCrypt::Password.new(ses.remember_token).is_password?(token)
  end

  def forget(token)
    lookup = Digest::SHA256.hexdigest(token)[0...24]
    return false unless ses = Session.find_by(id: lookup, deleted: false)
    ses.update!(deleted: true)
  end

  def self.find_by_token(token)
    lookup = Digest::SHA256.hexdigest(token)[0...24]
    return unless ses = Session.find_by(id: lookup, deleted: false)
    return ses.account
  end

end
