class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
  include S3Tools
  include ImageTools
  include TokenTools
  include Paginatable

  private

  NAME_ID_REGEX = /\A[a-zA-Z0-9_]+\z/
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i

  def set_aid
    self.aid ||= SecureRandom.base36(14)
  end
end
