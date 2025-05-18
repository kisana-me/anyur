class Document < ApplicationRecord
  enum :status, { draft: 0, unlisted: 1, specific: 2, published: 3 }, prefix: true

  before_create :generate_custom_id

  validates :name, presence: true
  validates :name, length: { in: 1..30 },
                    if: -> { name.present? }
  validates :name_id, presence: true
  validates :name_id, uniqueness: { case_sensitive: false },
                      length: { in: 5..30 },
                      format: { with: /\A[a-zA-Z0-9_-]+\z/, message: :invalid_name_id_format },
                      if: -> { name_id.present? }
end