class OauthService
  class TokenResponse
    attr_reader :access_token, :refresh_token, :token_type, :expires_in, :expires_at, :user, :scope
    
    def initialize(data)
      @access_token = data[:access_token]
      @refresh_token = data[:refresh_token]
      @token_type = data[:token_type]
      @expires_in = data[:expires_in]
      @expires_at = data[:expires_at]
      @user = data[:user]
      @scope = data[:scope]
    end
  end
  
  # Constructs an authorization URL for an upstream service
  # Similar to getUpstreamAuthorizeUrl in the TypeScript code
  def self.get_upstream_authorize_url(options)
    upstream_url = options[:upstream_url]
    client_id = options[:client_id]
    scope = options[:scope]
    redirect_uri = options[:redirect_uri]
    state = options[:state]
    
    uri = URI(upstream_url)
    params = URI.decode_www_form(uri.query || "")
    
    params << ["client_id", client_id]
    params << ["redirect_uri", redirect_uri]
    params << ["scope", scope]
    params << ["state", state] if state
    params << ["response_type", "code"]
    
    uri.query = URI.encode_www_form(params)
    uri.to_s
  end
  
  # Exchanges an authorization code for an access token
  # Similar to exchangeCodeForAccessToken in the TypeScript code
  def self.exchange_code_for_access_token(options)
    code = options[:code]
    upstream_url = options[:upstream_url]
    client_secret = options[:client_secret]
    client_id = options[:client_id]
    
    unless code
      Rails.logger.error("[oauth] Missing code in token exchange")
      return [nil, {status: 400, body: "Invalid request: missing authorization code"}]
    end
    
    begin
      params = {
        grant_type: "authorization_code",
        client_id: client_id,
        client_secret: client_secret,
        code: code
      }
      
      response = HTTParty.post(
        upstream_url,
        body: params,
        headers: { 'Content-Type' => 'application/x-www-form-urlencoded' }
      )
      
      unless response.success?
        Rails.logger.error("[oauth] Failed to exchange code for access token: #{response.body}")
        return [nil, {status: 400, body: "There was an issue authenticating your account and retrieving an access token. Please try again."}]
      end
      
      body = JSON.parse(response.body, symbolize_names: true)
      
      # Validate response schema (simplified from the Zod schema in TypeScript)
      token_response = TokenResponse.new(body)
      return [token_response, nil]
    rescue => e
      Rails.logger.error("Failed to parse token response: #{e.message}")
      return [nil, {status: 500, body: "There was an issue authenticating your account and retrieving an access token. Please try again."}]
    end
  end
end 