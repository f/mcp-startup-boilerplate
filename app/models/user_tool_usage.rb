# frozen_string_literal: true

class UserToolUsage < ApplicationRecord
  belongs_to :user
  
  validates :tool_name, presence: true
  validates :price_cents, numericality: { greater_than_or_equal_to: 0 }
  
  scope :for_tool, ->(tool_name) { where(tool_name: tool_name) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :latest, -> { order(created_at: :desc) }
  
  def refund!
    return false unless charge_id.present?
    
    begin
      refund = Stripe::Refund.create(charge: charge_id)
      update(refunded_at: Time.current, refund_id: refund.id)
      true
    rescue => e
      Rails.logger.error "Refund error: #{e.message}"
      false
    end
  end
end
