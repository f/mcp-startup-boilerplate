# frozen_string_literal: true

Doorkeeper.configure do
  # Detailed: https://github.com/doorkeeper-gem/doorkeeper/blob/main/lib/generators/doorkeeper/templates/initializer.rb
  orm :active_record

  resource_owner_authenticator do
    current_user || warden.authenticate!(scope: :user)
  end

  revoke_previous_client_credentials_token
  force_pkce
  hash_token_secrets
  hash_application_secrets
  use_refresh_token
  enable_application_owner confirmation: false
  access_token_methods :from_bearer_authorization, :from_access_token_param, :from_bearer_param
  realm "MCP"
  default_scopes :read
  grant_flows %w[authorization_code refresh_token]
end
