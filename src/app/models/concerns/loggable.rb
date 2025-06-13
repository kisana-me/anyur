module Loggable
  extend ActiveSupport::Concern

  included do
    after_create :log_create
    after_update :log_update
  end

  private

  def log_create
    return if self.is_a?(ActivityLog)
    ActivityLog.create!(
      account: Current.account,
      loggable: self,
      attribute_name: "",
      action_name: "create",
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
        account: Current.account,
        loggable: self,
        attribute_name: attr,
        action_name: "update",
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
