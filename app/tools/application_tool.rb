# frozen_string_literal: true

class ApplicationTool < ActionTool::Base
  # write your custom logic to be shared across all tools here
  def current_user
    self.class.server.transport.resource_owner
  end
end
