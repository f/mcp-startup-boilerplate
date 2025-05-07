class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    # Get the user's approved OAuth applications through their access tokens
    @access_tokens = current_user.access_tokens.where(revoked_at: nil)
                                 .includes(:application)
                                 .order('oauth_applications.name')
                                 .group_by(&:application)
  end
end
