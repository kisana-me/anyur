class Current < ActiveSupport::CurrentAttributes
  attribute :account, :ip_address, :user_agent, :request_id
end
