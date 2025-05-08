# MCP Startup Boilerplate

A robust, ready-to-use Rails boilerplate for building AI-powered applications that integrate seamlessly with Claude AI using the Model Context Protocol (MCP). This boilerplate includes user authentication and OAuth2 provider capabilities out of the box.

## 🚀 Features

- **User Authentication**: Complete authentication system powered by Devise
- **OAuth2 Provider**: Full OAuth2 server implementation with Doorkeeper
- **MCP Integration**: Seamless Claude AI integration using fast-mcp
- **Modern Rails**: Built on Rails 8.0.2 with the latest features
- **Tailwind CSS**: Beautiful, responsive UI with Tailwind
- **Hotwire**: Modern, fast frontend with Turbo and Stimulus

## 📋 Requirements

- Ruby 3.2+
- PostgreSQL
- Node.js & Yarn (for frontend assets)

## 🔧 Setup

### 1. Clone the repository

```bash
git clone https://your-repository-url.git
cd mcp-startup
```

### 2. Install dependencies

```bash
bundle install
yarn install
```

### 3. Setup the database

```bash
rails db:create db:migrate db:seed
```

### 4. Start the server

```bash
rails server
```

Your application should now be running at http://localhost:3000

## 🔒 OAuth2 Integration

This boilerplate comes with a complete OAuth2 server implementation powered by Doorkeeper. Key endpoints:

- OAuth Authorization: `/oauth/authorize`
- Token Endpoint: `/oauth/token`
- Application Registration: `/oauth/applications`
- Token Revocation: `/oauth/revoke`

The OAuth server supports:
- Authorization Code Flow
- Client Credentials Flow
- Refresh Token Flow
- PKCE Extension (S256 and plain)

## 🤖 MCP Integration

This boilerplate is pre-configured to work with Claude AI through the Model Context Protocol, enabling AI applications to securely access your application's data and functionality.

### Available MCP Resources

- `users/me` - Access information about the authenticated user

### Available MCP Tools

- `MeTool` - Get information about the currently authenticated user

## 🔌 Integrating with Claude

To connect your application with Claude:

1. Register your application in Claude Desktop or other Claude integrations
2. Configure your MCP server in Claude's configuration:

```json
{
  "mcpServers": {
    "your-server-name": {
      "command": "ruby",
      "args": [
        "/path/to/your/server.rb"
      ]
    }
  }
}
```

For Claude Desktop, this file is located at:
- macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
- Windows: `%APPDATA%\Claude\claude_desktop_config.json`

## 🔧 Customization

### Adding New MCP Tools

1. Create a new tool in `app/tools/`:

```ruby
class YourTool < ApplicationTool
  description 'Your tool description'

  arguments do
    required(:param_name).filled(:string).description('Parameter description')
  end

  def call(param_name:)
    # Your implementation
    
    # Access the current authenticated user
    user = current_user
    # Do something with the user data
    { user_id: user.id, result: "Processed data for #{user.email}" }
  end
end
```

2. Register the tool in your MCP configuration

### Adding New MCP Resources

1. Create a new resource in `app/resources/`:

```ruby
class YourResource < ApplicationResource
  uri 'your/resource/path'
  resource_name 'Your Resource'
  description 'Your resource description'
  mime_type 'application/json'

  def content
    # Access the current authenticated user
    user = current_user
    
    JSON.generate({
      user_id: user.id,
      email: user.email,
      # Additional user-specific data
      custom_data: user.custom_data
    })
  end
end
```

2. Register the resource in your MCP configuration

### Working with Current User

Both MCP Tools and Resources have access to the `current_user` method, which returns the authenticated user from the OAuth token. This allows you to:

- Retrieve user-specific data
- Perform user-authorized operations
- Maintain security by scoping operations to the authenticated user
- Build personalized AI experiences based on user context

For security reasons, always verify user permissions before exposing sensitive data or performing critical operations.

## 🛡️ Security Considerations

- All MCP endpoints require proper OAuth authentication
- User data is only accessible to authorized applications
- OAuth tokens can be revoked by users at any time
- PKCE extension is supported for public clients

## 📚 Further Reading

- [Doorkeeper Documentation](https://doorkeeper.gitbook.io/guides)
- [fast-mcp Documentation](https://github.com/yjacquin/fast-mcp)
- [Model Context Protocol Specification](https://github.com/anthropics/model-context-protocol)
- [Devise Documentation](https://github.com/heartcombo/devise)

## 📝 License

This project is available under the MIT License.

## 👥 Contributing

Contributions, issues, and feature requests are welcome!
