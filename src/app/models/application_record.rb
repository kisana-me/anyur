class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def generate_base36(length = 128)
    SecureRandom.base36(length)
  end

  def generate_lookup(token, length = 36)
    Digest::SHA256.hexdigest(token)[ 0 ... length ]
  end

  def generate_digest(token)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST : BCrypt::Engine.cost
    BCrypt::Password.create(token, cost: cost)
  end

  def self.find_by_token(type, token)
    lookup = new.generate_lookup(token)
    record = where("#{type}_expires_at > ?", Time.current)
      .find_by("#{type}_lookup": lookup, status: 0, deleted: false)
    return nil unless record
    digest = record.send("#{type}_digest")
    return nil unless BCrypt::Password.new(digest).is_password?(token)
    record
  end

  def generate_token(type, expires_in = 0)
    token = generate_base36()
    lookup = generate_lookup(token)
    digest = generate_digest(token)
    self.send("#{type}_lookup=", lookup)
    self.send("#{type}_digest=", digest)
    self.send("#{type}_generated_at=", Time.current)
    self.send("#{type}_expires_at=", Time.current + expires_in)
    token
  end

  private

  NAME_ID_REGEX = /\A[a-zA-Z0-9_]+\z/
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i

  def generate_custom_id
    self.id ||= SecureRandom.base36(14)
  end
end
