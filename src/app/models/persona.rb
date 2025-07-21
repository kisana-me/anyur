class Persona < ApplicationRecord
  attribute :scopes, :json, default: []
  attribute :meta, :json, default: {}
  enum :status, { normal: 0, locked: 1 }, prefix: true

  belongs_to :account
  belongs_to :service

  before_create :set_aid
  before_create :initialize_tokens

  validates :name, presence: true
  validates :name, length: { in: 1..30 },
                    if: -> { name.present? }

  private

  def initialize_tokens
    generate_token("authorization_code")
    generate_token("access_token")
    generate_token("refresh_token")
  end
end
