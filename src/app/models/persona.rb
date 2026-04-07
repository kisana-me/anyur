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

  def with_challenge(code_challenge, code_challenge_method)
    # self.meta ||= {}
    if code_challenge.blank? || code_challenge_method.blank?
      self.meta.delete("challenge")
    else
      challenge = {
        code_challenge: code_challenge,
        code_challenge_method: code_challenge_method
      }
      self.meta["challenge"] = challenge
    end
  end

  private

  def initialize_tokens
    generate_token(0, "authorization_code")
    generate_token(0, "access_token")
    generate_token(0, "refresh_token")
  end
end
