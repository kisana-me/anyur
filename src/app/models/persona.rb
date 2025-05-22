class Persona < ApplicationRecord
  belongs_to :account
  belongs_to :service

  before_create :generate_custom_id

  validates :name, presence: true
  validates :name, length: { in: 1..30 },
                    if: -> { name.present? }

  def generate_authorization_code
    token = generate_base36(32)
    digest = digest(token)
    lookup = Digest::SHA256.hexdigest(token)[0...24]
  end

  def generate_access_token
    token = generate_base36(48)
    digest = digest(token)
    lookup = Digest::SHA256.hexdigest(token)[0...24]
  end

  def generate_refresh_token
    generate_base36(64)
    digest = digest(token)
    lookup = Digest::SHA256.hexdigest(token)[0...24]
  end

  def authorization_code_expired?
    authorization_code_generated_at && Time.current > authorization_code_generated_at + 10.minutes
  end

  def access_token_expired?
    access_token_expires_at && Time.current > access_token_expires_at
  end

  def refresh_token_expired?
    refresh_token_expires_at && Time.current > refresh_token_expires_at
  end
end
