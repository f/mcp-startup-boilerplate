Rails.configuration.stripe = {
  publishable_key: ENV['STRIPE_PUBLISHABLE_KEY'] || 'pk_test_example',
  secret_key: ENV['STRIPE_SECRET_KEY'] || 'sk_test_example',
  signing_secret: ENV['STRIPE_WEBHOOK_SECRET'] || 'whsec_example'
}

Stripe.api_key = Rails.configuration.stripe[:secret_key] 