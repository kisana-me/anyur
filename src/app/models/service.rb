class Service < ApplicationRecord
  before_create :generate_custom_id
  before_save :cache_rendered_content

  validates :name, presence: true
  validates :name, length: { in: 1..30 },
                    if: -> { name.present? }
  validates :name_id, presence: true
  validates :name_id, uniqueness: { case_sensitive: false },
                      length: { in: 5..30 },
                      format: { with: NAME_ID_REGEX, message: :invalid_name_id_format },
                      if: -> { name_id.present? }

  private

  def cache_rendered_content
    self.description_cache = ::MarkdownRenderer.render(description)
  end
end
