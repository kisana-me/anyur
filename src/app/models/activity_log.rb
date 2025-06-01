class ActivityLog < ApplicationRecord
  belongs_to :account

  attribute :meta, :json, default: {}
end