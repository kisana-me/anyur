class ActivityLog < ApplicationRecord

  belongs_to :account, optional: true
  attribute :meta, :json, default: {}

  before_create :set_aid

end
