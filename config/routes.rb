Rails.application.routes.draw do
  use_doorkeeper scope: 'auth'
  
  # OAuth application registration API endpoint (no CSRF)
  post '/oauth/register', to: 'oauth_applications#create'
  get '/oauth/authorize', to: 'oauth#authorize', as: :authorize_oauth
  get '/oauth/token', to: 'oauth#token', as: :token_oauth
  get '/oauth/callback', to: 'oauth#callback', as: :callback_oauth
  
  # OAuth server metadata for discovery
  get '/.well-known/oauth-authorization-server', to: 'oauth_metadata#authorization_server'
  
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
end
