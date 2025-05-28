class Session < ApplicationRecord
  self.primary_key = "id"
  belongs_to :account
  attribute :meta, :json, default: {}
end
