module TokenTools
  # ver 1.0.0
  # 必要なカラム(名前 型)
  # - ??_lookup string
  # - ??_digest string
  # - ??_generated_at string
  # - ??_expires_at string
  # - deleted boolean

  LOOKUP_LENGTH = 36
  BASE36_LENGTH = 128
  extend ActiveSupport::Concern

  def generate_lookup(token, length = LOOKUP_LENGTH)
    Digest::SHA256.hexdigest(token)[ 0 ... length ]
  end

  def generate_digest(token)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST : BCrypt::Engine.cost
    BCrypt::Password.create(token, cost: cost)
  end

  def generate_token(type, expires_in = 0)
    token = SecureRandom.base36(BASE36_LENGTH)
    lookup = generate_lookup(token)
    digest = generate_digest(token)
    self.send("#{type}_lookup=", lookup)
    self.send("#{type}_digest=", digest)
    self.send("#{type}_generated_at=", Time.current)
    self.send("#{type}_expires_at=", Time.current + expires_in)
    return token
  end

  class_methods do
    def find_by_token(type, token)
      lookup = new.generate_lookup(token)
      record = where("#{type}_expires_at > ?", Time.current)
        .find_by("#{type}_lookup": lookup, deleted: false)
      return nil unless record
      digest = record.send("#{type}_digest")
      return nil unless BCrypt::Password.new(digest).is_password?(token)
      record
    end
  end
end
