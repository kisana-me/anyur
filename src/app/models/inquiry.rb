class Inquiry < ApplicationRecord
  include Loggable

  attribute :meta, :json, default: -> { {} }
  attr_accessor :service_aid
  enum :status, { normal: 0, locked: 1, deleted: 2 }

  belongs_to :account, optional: true
  belongs_to :service, optional: true

  validates :subject,
    presence: true,
    length: { in: 1..255, allow_blank: true }
  validates :content,
    presence: true,
    length: { in: 1..5000, allow_blank: true }
  validates :name,
    presence: true,
    length: { in: 1..255, allow_blank: true }
  validates :email,
    length: { in: 1..255, allow_blank: true },
    format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }
  validates :memo,
    length: { in: 1..5000, allow_blank: true }

  before_create :set_aid
  before_validation :normalize_service_aid

  scope :is_normal, -> { where(status: :normal) }
  scope :isnt_deleted, -> { where.not(status: :deleted) }

  private

  def normalize_service_aid
    self.service_aid = nil if service_aid.blank?
  end
end
