module Loggable
  extend ActiveSupport::Concern

  included do
    after_create :log_create
    after_update :log_update
  end

  private

  # record_nameとtarget_aidはポリモーフィック?できるか？

  def log_create
    return if self.is_a?(ActivityLog)
    ActivityLog.create!(
      aid: SecureRandom.base36(14),
      account: Current.account,
      record_name: self.class.name,
      attribute_name: "",
      action_name: "create",
      target_aid: self.aid,
      value: "",
      changed_at: Time.current,
      change_reason: "",
      user_agent: Current.user_agent.to_s,
      ip_address: Current.ip_address.to_s,
      meta: {}
    )
  end

  def log_update
    return if self.is_a?(ActivityLog)
    saved_changes.except(:updated_at).each do |attr, (before, after)|
      next if before == after

      ActivityLog.create!(
        aid: SecureRandom.base36(14),
        account: Current.account,
        record_name: self.class.name,
        attribute_name: attr,
        action_name: "update",
        target_aid: self.aid,
        value: before.to_s,
        changed_at: Time.current,
        change_reason: "",
        user_agent: Current.user_agent.to_s,
        ip_address: Current.ip_address.to_s,
        meta: {}
      )
    end
  end
end
