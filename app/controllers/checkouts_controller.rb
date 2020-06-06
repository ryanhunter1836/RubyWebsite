class CheckoutsController < ApplicationController
before_action :logged_in_user,  only: [:new]
before_action :calculate_total

def success
end

def cancelled
end

def setup
  respond_to do |format|
    msg = { :publishableKey => Rails.application.credentials.publishable_key,
            :basicPrice => 'price_HOCBNh8YbXGni6',
            :proPrice => 'price_HOCCywRPMNyAFh' }
    format.json { render :json => msg } 
  end
end

def create_checkout_session
  data = JSON.parse request.body.read
  # Create new Checkout Session for the order
  # Other optional params include:
  # [billing_address_collection] - to display billing address details on the page
  # [customer] - if you have an existing Stripe Customer ID
  # [customer_email] - lets you prefill the email input in the form
  # For full details see https:#stripe.com/docs/api/checkout/sessions/create

  # ?session_id={CHECKOUT_SESSION_ID} means the redirect will have the session ID set as a query param
  session = Stripe::Checkout::Session.create(
    customer_email: current_user.email,
    success_url: 'http://localhost:3000/checkouts/success.html?session_id={CHECKOUT_SESSION_ID}',
    cancel_url: 'http://localhost:3000/checkouts/canceled.html',
    payment_method_types: ['card'],
    mode: 'subscription',
    billing_address_collection: 'auto',
    shipping_address_collection: {
    allowed_countries: ['US'],
    },
    line_items: [{
      quantity: 1,
      price: data['priceId'],
    }]
  )

  respond_to do |format|
    msg = { :sessionId => session['id'] }
    format.json { render :json => msg } 
  end
end

def webhook
  # You can use webhooks to receive information about asynchronous payment events.
  # For more about our webhook events check out https://stripe.com/docs/webhooks.
  webhook_secret = ENV['STRIPE_WEBHOOK_SECRET']
  payload = request.body.read
  if !webhook_secret.empty?
    # Retrieve the event by verifying the signature using the raw body and secret if webhook signing is configured.
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    event = nil

    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, webhook_secret
      )
    rescue JSON::ParserError => e
      # Invalid payload
      status 400
      return
    rescue Stripe::SignatureVerificationError => e
      # Invalid signature
      puts '⚠️  Webhook signature verification failed.'
      status 400
      return
    end
  else
    data = JSON.parse(payload, symbolize_names: true)
    event = Stripe::Event.construct_from(data)
  end
  # Get the type of webhook event sent - used to check the status of PaymentIntents.
  event_type = event['type']
  data = event['data']
  data_object = data['object']

  puts '🔔  Payment succeeded!' if event_type == 'checkout.session.completed'

  content_type 'application/json'
  {
    status: 'success'
  }.to_json
end


private

#Method to calculate the total price of the subscription
def calculate_total
    500
end

end