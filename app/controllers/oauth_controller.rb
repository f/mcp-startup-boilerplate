class OauthController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  # Constants similar to the TypeScript code
  AUTH_URL = "/auth/authorize/".freeze
  TOKEN_URL = "/auth/token/".freeze
  CALLBACK_URL = "/auth/callback/".freeze
  # OAuth Authorization Endpoint
  # This route initiates the OAuth flow when a user wants to log in
  def authorize
    # Get the application - either from params or automatically
    application = if params[:client_id].present?
                    Doorkeeper::Application.find_by(uid: params[:client_id])
                  else
                    # Try to find a default application if client_id is not provided
                    Doorkeeper::Application.first
                  end
    
    if !application
      return render plain: "Invalid request", status: 400
    end
    
    # Store OAuth request info in state parameter (similar to parseAuthRequest in the TypeScript code)
    oauth_req_info = {
      clientId: application.uid,
      redirectUri: params[:redirect_uri],
      scope: params[:scope] || '',
      state: params[:state]
    }
    
    # Redirect to Doorkeeper's authorization URL using our service
    redirect_url = OauthService.get_upstream_authorize_url({
      upstream_url: "#{request.base_url}#{AUTH_URL}",
      client_id: application.uid,
      redirect_uri: "#{request.base_url}#{CALLBACK_URL}",
      scope: Doorkeeper.configuration.default_scopes,
      state: Base64.strict_encode64(oauth_req_info.to_json)
    })

    redirect_to redirect_url
  end
  
  # OAuth Callback Endpoint
  # This route handles the callback after user authentication
  def callback
    # Get the OAuth request info from the state (similar to the TypeScript code)
    begin
      oauth_req_info = JSON.parse(Base64.strict_decode64(params[:state]), symbolize_names: true)
    rescue
      return render plain: "Invalid state", status: 400
    end
    
    if !oauth_req_info[:clientId]
      return render plain: "Invalid state", status: 400
    end
    
    # Find the application
    application = Doorkeeper::Application.find_by(uid: oauth_req_info[:clientId])
    
    if !application
      # Try to find a default application if the one from state can't be found
      application = Doorkeeper::Application.first
      return render plain: "Invalid application", status: 400 if !application
    end
    
    # Exchange the code for an access token using our service
    payload, error_response = OauthService.exchange_code_for_access_token({
      upstream_url: "#{request.base_url}#{TOKEN_URL}",
      client_id: application.uid,
      client_secret: application.secret,
      code: params[:code]
    })
    
    if error_response
      return render plain: error_response[:body], status: error_response[:status]
    end
    
    # Get user data
    user = current_user
    
    # Simulate the completeAuthorization functionality
    # In the TypeScript code this would be:
    # c.env.OAUTH_PROVIDER.completeAuthorization({
    #   request: oauthReqInfo,
    #   userId: payload.user.id,
    #   metadata: { label: payload.user.email },
    #   scope: oauthReqInfo.scope,
    #   props: { ... }
    # });
    # 
    # In Rails, we'll redirect to the client's callback URL with the token
    
    # Create the token for the client
    token = Doorkeeper::AccessToken.create!(
      application_id: application.id,
      resource_owner_id: user.id,
      scopes: oauth_req_info[:scope],
      expires_in: Doorkeeper.configuration.access_token_expires_in,
      use_refresh_token: Doorkeeper.configuration.refresh_token_enabled?
    )
    
    # Prepare the token data to pass to the client
    token_data = {
      access_token: token.token,
      token_type: "Bearer",
      expires_in: token.expires_in,
      refresh_token: token.refresh_token,
      created_at: token.created_at.to_i,
      user_id: user.id,
      user_email: user.email,
      scope: oauth_req_info[:scope]
    }

    Rails.logger.info("Token data: #{token_data}")
    
    # Redirect back to the client's callback URL
    # Include state if the original request had one
    redirect_params = {
      token: token.token,
      state: oauth_req_info[:state]
    }
    
    redirect_uri = oauth_req_info[:redirectUri]
    redirect_to "#{redirect_uri}?#{redirect_params.to_query}"
  end
end 