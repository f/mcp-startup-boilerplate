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

  # Landing page for non-authenticated users
  get 'landing', to: 'home#landing'
  
  # Dashboard and authenticated routes
  get 'dashboard', to: 'home#index', as: :dashboard
  get 'ai_apps', to: 'home#ai_apps', as: :ai_apps
  get 'call_history', to: 'home#call_history', as: :call_history
  
  # Subscription management
  resources :subscriptions, only: [:index, :new, :create, :destroy]
  get 'subscriptions/success', to: 'subscriptions#success', as: :subscription_success
  get 'subscriptions/cancel', to: 'subscriptions#cancel', as: :subscription_cancel
  
  # Stripe webhook endpoints
  post 'webhooks/stripe', to: 'webhooks#stripe'

  # Defines the root path route ("/")
  root "home#landing"

  # OAuth server metadata for discovery
  get '/.well-known/oauth-authorization-server', to: 'application#oauth_metadata'
end
