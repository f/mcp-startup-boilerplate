Rails.application.routes.draw do  
  use_doorkeeper
  # Removing redundant route that can cause conflicts with Doorkeeper's built-in token endpoint
  # post '/oauth/token', to: 'doorkeeper/tokens#create' 

  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"

  # OAuth server metadata for discovery
  get '/.well-known/oauth-authorization-server', to: 'application#oauth_metadata'
end
