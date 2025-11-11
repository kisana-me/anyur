class Document < ApplicationRecord
  attribute :meta, :json, default: -> { {} }
  enum :visibility, { closed: 0, limited: 1, opened: 2 }
  enum :status, { normal: 0, locked: 1, deleted: 2, specific: 3 }

  before_create :set_aid

  validates :name_id,
    presence: true,
    length: { in: 5..50, allow_blank: true },
    format: { with: NAME_ID_REGEX, message: :invalid_name_id_format, allow_blank: true },
    uniqueness: { case_sensitive: false, allow_blank: true }
  validates :title,
    presence: true,
    length: { in: 1..50, allow_blank: true }
  validates :summary,
    presence: true,
    length: { in: 1..500, allow_blank: true }
  validates :content,
    presence: true,
    length: { in: 1..100_000, allow_blank: true }

  scope :is_normal, -> { where(status: :normal) }
  scope :isnt_deleted, -> { where.not(status: :deleted) }
  scope :is_opened, -> { where(visibility: :opened) }
  scope :isnt_closed, -> { where.not(visibility: :closed) }
end
