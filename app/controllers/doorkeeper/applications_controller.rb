module Doorkeeper
  class Doorkeeper::ApplicationsController < Doorkeeper::ApplicationController
    skip_before_action :verify_authenticity_token, only: [:create]
    
    def create
      @application = Doorkeeper::Application.find_or_initialize_by(name: application_params[:name])
      @application.assign_attributes(application_params)
      if @application.save
        render json: {
          client_id: @application.uid,
          client_secret: @application.secret,
          client_name: @application.name,
          redirect_uris: @application.redirect_uri.split,
          grant_types: ["authorization_code", "refresh_token"],
          response_types: ["code"],
          scope: @application.scopes.to_s,
          created_at: @application.created_at.iso8601
        }, status: :created
      else
        render json: { errors: @application.errors.full_messages }, status: :unprocessable_entity
      end
    rescue => e
      Rails.logger.error("Error creating OAuth application: #{e.message}")
      render json: { errors: e.message }, status: :unprocessable_entity
    end
    
    private
    
    def application_params
      # Map the dynamic client registration params to Doorkeeper's expected format
      {
        name: params[:client_name],
        redirect_uri: Array(params[:redirect_uris]).join("\n"),
        scopes: params[:scope],
        confidential: false
      }
    end
  end 
end