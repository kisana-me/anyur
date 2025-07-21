module Loggable
  # ver 1.0.1
  # 下3つ必須
  # models/current.rb 作成
  # models/activity_log.rb 作成
  # controllers/application_controller.rb 追記
  # db/activity_log.rb

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
      action_name: "create",
      attribute_data: [],
      changed_at: Time.current,
      change_reason: "",
      user_agent: Current.user_agent.to_s,
      ip_address: Current.ip_address.to_s,
      meta: {}
    )
  end

  def log_update
    return if self.is_a?(ActivityLog)
    changes_to_log = saved_changes.except(:updated_at).filter_map do |attr, (before, after)|
      next if before == after
      { attribute_name: attr, attribute_value: before.to_s }
    end
    return if changes_to_log.empty?
    ActivityLog.create!(
      account: Current.account,
      loggable: self,
      action_name: "update",
      attribute_data: changes_to_log,
      changed_at: Time.current,
      change_reason: "",
      user_agent: Current.user_agent.to_s,
      ip_address: Current.ip_address.to_s,
      meta: {}
    )
  end
end
