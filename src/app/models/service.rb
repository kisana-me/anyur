class Service < ApplicationRecord
  attribute :redirect_uris, :json, default: -> { [] }
  attribute :scopes, :json, default: -> { [] }
  attribute :meta, :json, default: -> { {} }
  enum :status, { normal: 0, locked: 1, deleted: 2 }

  before_create :set_aid
  before_create :initialize_tokens

  validates :name,
    presence: true,
    length: { in: 1..30, allow_blank: true }
  validates :name_id,
    presence: true,
    length: { in: 5..30, allow_blank: true },
    format: { with: NAME_ID_REGEX, message: :invalid_name_id_format, allow_blank: true },
    uniqueness: { case_sensitive: false, allow_blank: true }

  scope :is_normal, -> { where(status: :normal) }
  scope :isnt_deleted, -> { where.not(status: :deleted) }

  private

  def initialize_tokens
    generate_token(0, "client_secret")
  end
end
