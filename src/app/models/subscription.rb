class Subscription < ApplicationRecord
  belongs_to :account

  enum :status, {
    incomplete: 0,
    incomplete_expired: 1,
    trialing: 2,
    active: 3,
    past_due: 4,
    canceled: 5,
    unpaid: 6
  }

  before_create :generate_custom_id

  validates :stripe_subscription_id, presence: true, uniqueness: true
  validates :stripe_plan_id, presence: true
  validates :status, presence: true

  # スコープ
  scope :active_or_trialing, -> { where(status: [:active, :trialing]) }
  scope :canceled, -> { where(status: :canceled) }

  def active_or_trialing?
    active? || trialing?
  end
end