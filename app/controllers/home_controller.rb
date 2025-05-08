class HomeController < ApplicationController
  before_action :authenticate_user!, except: [:landing]

  def index
    # Get the user's approved OAuth applications through their access tokens
    @access_tokens = current_user.access_tokens.where(revoked_at: nil)
                                 .includes(:application)
                                 .order('oauth_applications.name')
                                 .group_by(&:application)
  end

  def landing
    # Redirect to dashboard if user is already logged in
    redirect_to dashboard_path if user_signed_in?
  end

  def ai_apps
    # Logic for AI applications will go here
    @applications = Doorkeeper::Application.all
  end

  def call_history
    # Get all tool usage with pagination
    @tool_usages = current_user.tool_usages.latest.page(params[:page]).per(20)
    
    # Get usage statistics
    @total_calls = current_user.tool_usage_count
    @total_spent = current_user.total_spent_cents
    
    # Get usage breakdown by tool
    @usage_by_tool = current_user.tool_usages
                                .group(:tool_name)
                                .select('tool_name, COUNT(*) as count, SUM(price_cents) as total')
                                .order('count DESC')
  end
end
