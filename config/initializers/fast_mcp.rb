# frozen_string_literal: true

# FastMcp - Model Context Protocol for Rails
# This initializer sets up the MCP middleware in your Rails application.
#
# In Rails applications, you can use:
# - ActionTool::Base as an alias for FastMcp::Tool
# - ActionResource::Base as an alias for FastMcp::Resource
#
# All your tools should inherit from ApplicationTool which already uses ActionTool::Base,
# and all your resources should inherit from ApplicationResource which uses ActionResource::Base.

# Mount the MCP middleware in your Rails application
# You can customize the options below to fit your needs.
require 'fast_mcp'

class FastMcp::Transports::AuthenticatedRackTransport < FastMcp::Transports::RackTransport
  def handle_mcp_request(request, env)
    auth_header = request.env["HTTP_AUTHORIZATION"]
    
    token = auth_header&.gsub('Bearer ', '')
    access_token = Doorkeeper::AccessToken.by_token(token)
    if access_token.present?
      @resource_owner = User.find(access_token.resource_owner_id)
    else
      @resource_owner = nil
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
  # Add allowed origins below, it defaults to Rails.application.config.hosts
  allowed_origins: ['localhost', '127.0.0.1', '[::1]', '34.162.102.82', /.*\.ngrok-free\.app/],
  # localhost_only: true, # Set to false to allow connections from other hosts
  # whitelist specific ips to if you want to run on localhost and allow connections from other IPs
  allowed_ips: ['127.0.0.1', '::1', '34.162.102.82', '34.162.183.95'],
  authenticate: true,  # Uncomment to enable authentication
  # auth_token: 'your-token', # Required if authenticate: true
) do |server|
  Rails.application.config.after_initialize do
    # FastMcp will automatically discover and register:
    # - All classes that inherit from ApplicationTool (which uses ActionTool::Base)
    # - All classes that inherit from ApplicationResource (which uses ActionResource::Base)
    server.register_tools(*ApplicationTool.descendants)
    server.register_resources(*ApplicationResource.descendants)
    # alternatively, you can register tools and resources manually:
    # server.register_tool(MyTool)
    # server.register_resource(MyResource)
  end
end
