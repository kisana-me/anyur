class Persona < ApplicationRecord
  attribute :scopes, :json, default: -> { [] }
  attribute :meta, :json, default: -> { {} }
  enum :status, { normal: 0, locked: 1, deleted: 2 }

  belongs_to :account
  belongs_to :service

  before_create :set_aid
  before_create :initialize_tokens

  validates :name,
    presence: true,
    length: { in: 1..30, allow_blank: true }

  scope :is_normal, -> { where(status: :normal) }
  scope :isnt_deleted, -> { where.not(status: :deleted) }

  private

  def initialize_tokens
    generate_token("authorization_code")
    generate_token("access_token")
    generate_token("refresh_token")
  end
end
