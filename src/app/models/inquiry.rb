class Inquiry < ApplicationRecord
  self.primary_key = "id"

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

  before_create :generate_custom_id
  before_validation :normalize_service_id

  private

  def normalize_service_id
    self.service_id = nil if service_id.blank?
  end
end
