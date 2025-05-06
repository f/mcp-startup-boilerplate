class OauthMetadataController < ApplicationController
  def authorization_server
    base_url = "#{request.protocol}#{request.host_with_port}"
    
    metadata = {
      issuer: base_url,
      authorization_endpoint: "#{base_url}/oauth/authorize",
      token_endpoint: "#{base_url}/oauth/token",
      registration_endpoint: "#{base_url}/oauth/register",
      scopes_supported: ["read", "write", "profile", "claudeai"],
      response_types_supported: ["code"],
      response_modes_supported: ["query"],
      grant_types_supported: ["authorization_code", "refresh_token"],
      token_endpoint_auth_methods_supported: [
        "client_secret_basic", 
        "client_secret_post", 
        "none"
      ],
      revocation_endpoint: "#{base_url}/oauth/revoke",
      code_challenge_methods_supported: ["plain", "S256"]
    }

    render json: metadata
  end
end 