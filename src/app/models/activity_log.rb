class ActivityLog < ApplicationRecord
  belongs_to :account, optional: true
  belongs_to :loggable, polymorphic: true, optional: true
  attribute :attribute_data, :json, default: -> { [] }
  attribute :meta, :json, default: -> { {} }
  enum :status, { normal: 0, locked: 1, deleted: 2 }

  before_create :set_aid
end
