class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  private

  def generate_custom_id
    self.id ||= SecureRandom.base36(14)
  end
end
