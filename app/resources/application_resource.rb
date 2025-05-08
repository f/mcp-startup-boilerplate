# frozen_string_literal: true

class ApplicationResource < ActionResource::Base
  # write your custom logic to be shared across all resources here

  def current_user
    self.class.server.transport.resource_owner
  end
end
