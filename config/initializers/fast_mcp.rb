# frozen_string_literal: true

require 'fast_mcp'

class FastMcp::Transports::AuthenticatedRackTransport < FastMcp::Transports::RackTransport
  def handle_mcp_request(request, env)
    auth_header = request.env["HTTP_AUTHORIZATION"]
    
    token = auth_header&.gsub('Bearer ', '')
    access_token = Doorkeeper::AccessToken.by_token(token)
    # Check if the access token exists and is not revoked
    if access_token.nil? || access_token.revoked?
      return unauthorized_response(request)
    end

    if access_token.present? && access_token.resource_owner_id.present?
      @resource_owner = User.find(access_token.resource_owner_id)
    else
      return unauthorized_response(request)
    end

    super
  end

  def resource_owner
    @resource_owner
  end
end

FastMcp.mount_in_rails(
  Rails.application,
  name: Rails.application.class.module_parent_name.underscore.dasherize,
  version: '1.0.0',
  path_prefix: '/mcp', # This is the default path prefix
  messages_route: 'messages', # This is the default route for the messages endpoint
  sse_route: 'sse', # This is the default route for the SSE endpoint
  localhost_only: false, # Set to false to allow connections from other hosts
  authenticate: true,  # Uncomment to enable authentication
) do |server|
  Rails.application.config.after_initialize do
    server.register_tools(*ApplicationTool.descendants)
    server.register_resources(*ApplicationResource.descendants)
  end
end
