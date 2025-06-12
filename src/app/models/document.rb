class Document < ApplicationRecord

  attribute :cache, :json, default: {}
  attribute :meta, :json, default: {}
  attribute :settings, :json, default: {}

  enum :status, { draft: 0, unlisted: 1, specific: 2, published: 3 }, prefix: true

  before_create :set_aid
  before_save :cache_rendered_content

  validates :name, presence: true
  validates :name, length: { in: 1..50 },
                    if: -> { name.present? }
  validates :name_id, presence: true
  validates :name_id, uniqueness: { case_sensitive: false },
                      length: { in: 5..50 },
                      format: { with: NAME_ID_REGEX, message: :invalid_name_id_format },
                      if: -> { name_id.present? }

  private

  def cache_rendered_content
    self.content_cache = ::MarkdownRenderer.render(content)
  end

end
