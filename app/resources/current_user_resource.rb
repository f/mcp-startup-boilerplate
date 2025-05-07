# frozen_string_literal: true

class CurrentUserResource < ApplicationResource
  uri 'users/me'
  resource_name 'Current User'
  description 'The current logged in user'
  mime_type 'application/json'

  def content
    current_user = CurrentUserResource.server.transport.resource_owner
    JSON.generate({
      id: current_user.id,
      email: current_user.email,
    })
  end
end
