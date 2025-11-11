class Current < ActiveSupport::CurrentAttributes
  attribute :account, :ip, :user_agent, :request_id
end
