Rails.configuration.stripe = {
    publishable_key: Rails.application.credentials.publishable_key,
    secret_key:      Rails.application.credentials.secret_key
  }
  
  Stripe.api_key = Rails.configuration.stripe[:secret_key]