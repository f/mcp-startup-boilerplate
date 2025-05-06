class Doorkeeper::ApplicationsController < Doorkeeper::ApplicationController
  skip_before_action :verify_authenticity_token
  
  # Let Doorkeeper handle the controller actions through inheritance
end 