class ApplicationRecord < ActiveRecord::Base

  primary_abstract_class
  include TokenTools

  private

  NAME_ID_REGEX = /\A[a-zA-Z0-9_]+\z/
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i

  def generate_custom_id
    self.id ||= SecureRandom.base36(14)
  end

end
