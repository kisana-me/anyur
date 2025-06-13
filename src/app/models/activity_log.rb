class ActivityLog < ApplicationRecord
  belongs_to :account, optional: true
  belongs_to :loggable, polymorphic: true, optional: true
  attribute :meta, :json, default: {}

  before_create :set_aid
end
