class Inquiry < ApplicationRecord
  attribute :meta, :json, default: {}
  attr_accessor :service_aid
  enum :status, { normal: 0, locked: 1 }, prefix: true

  belongs_to :account, optional: true
  belongs_to :service, optional: true

  validates :subject, presence: true
  validates :subject, length: { in: 1..255 },
                      if: -> { subject.present? }
  validates :summary, length: { in: 1..255 },
                      if: -> { summary.present? }
  validates :content, presence: true
  validates :content, length: { in: 1..4000 },
                      if: -> { content.present? }
  validates :name, presence: true,
                   if: -> { account.blank? }
  validates :name, length: { in: 1..255 },
                   if: -> { name.present? }
  validates :email, length: { in: 1..255 },
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    if: -> { email.present? }

  enum :status, { received: 0, processing: 1, finished: 2 }, prefix: true

  before_create :set_aid
  before_validation :normalize_service_aid

  private

  def normalize_service_aid
    self.service_aid = nil if service_aid.blank?
  end
end
