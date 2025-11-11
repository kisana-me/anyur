class Subscription < ApplicationRecord
  belongs_to :account

  attribute :meta, :json, default: -> { {} }
  enum :status, { normal: 0, locked: 1, deleted: 2 }
  enum :subscription_status, {
    incomplete: 0,
    incomplete_expired: 1,
    trialing: 2,
    active: 3,
    past_due: 4,
    canceled: 5,
    unpaid: 6
  }

  before_create :set_aid

  validates :stripe_subscription_id, presence: true, uniqueness: true
  validates :stripe_plan_id, presence: true
  validates :subscription_status, presence: true

  scope :is_normal, -> { where(status: :normal) }
  scope :isnt_deleted, -> { where.not(status: :deleted) }
  scope :active_or_trialing, -> { where(subscription_status: [ :active, :trialing ]) }
  scope :canceled, -> { where(subscription_status: :canceled) }
end
