class ActivityLog < ApplicationRecord

  belongs_to :account
  attribute :meta, :json, default: {}

  before_create :set_aid

end
