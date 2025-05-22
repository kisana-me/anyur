class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  private

  NAME_ID_REGEX = /\A[a-zA-Z0-9_]+\z/

  def generate_custom_id
    self.id ||= SecureRandom.base36(14)
  end

  def generate_base36(length)
    chars = ("a".."z").to_a + ("0".."9").to_a
    Array.new(length) { chars[SecureRandom.random_number(chars.size)] }.join
  end

  def digest(token)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST : BCrypt::Engine.cost
    BCrypt::Password.create(token, cost: cost)
  end
end
