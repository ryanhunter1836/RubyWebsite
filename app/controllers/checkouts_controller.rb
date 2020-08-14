class CheckoutsController < ApplicationController
protect_from_forgery except: :stripe_webhook

#Create the user account             
def create
  user = User.create(signup_params)

  if user.save
    user.order_options[0].initialize_stripe_products()
    user.send_activation_email
    #Tie the shipping addresses to the order option
    #Use the first entry in the collection since there is only 1 because this
    # is a new user
    user.shipping_addresses[0].order_option_id = user.order_options[0].id
    user.save

    #Log in the user for use in the Stripe payment
    log_in user
  end
  render json: user.errors
end

def setup
  respond_to do |format|
    msg = { :publishableKey => Rails.application.credentials.publishable_key }
    format.json { render :json => msg } 
  end
end

#Create a new Stripe customer
def create_customer
  # Create a new customer object
  customer = Stripe::Customer.create(email: current_user.email)

  current_user.stripeCustomerId = customer.id
  current_user.save

  respond_to do |format|
    msg = { :customer => customer, :name => current_user.name }
    format.json { render :json => msg } 
  end
end

#Create a subscription for the customer
def create_subscription
  data = JSON.parse request.body.read
  @order = current_user.order_options[0]
  @order.initialize_stripe_products

  begin
    Stripe::PaymentMethod.attach(
      data['paymentMethodId'],
      { customer: data['customerId'] }
    )
  rescue Stripe::CardError => e
    halt 200, { 'Content-Type' => 'application/json' }, { 'error': { message: e.error.message } }.to_json
  end

  #Save the payment id to the user
  current_user.paymentMethodId = data['paymentMethodId']
  current_user.save

  # Set the default payment method on the customer
  Stripe::Customer.update(
    data['customerId'],
    invoice_settings: {
      default_payment_method: data['paymentMethodId']
    }
  )

  # Create the subscription
  subscription = Stripe::Subscription.create(
    customer: data['customerId'],
    items: @order.get_products_hash,
    expand: ['latest_invoice.payment_intent']
  )

  @order.subscription_id = subscription.id
  @order.add_subscription_ids(subscription)
  @order.save

  render json: subscription
end

def retry_invoice
  data = JSON.parse request.body.read

  begin
    Stripe::PaymentMethod.attach(
      data['paymentMethodId'],
      { customer: data['customerId'] }
    )
  rescue Stripe::CardError => e
    halt 200, { 'Content-Type' => 'application/json' }, { 'error': { message: e.error.message } }.to_json
  end

  # Set the default payment method on the customer
  Stripe::Customer.update(
    data['customerId'],
    invoice_settings: {
      default_payment_method: data['paymentMethodId']
    }
  )

  invoice = Stripe::Invoice.retrieve({
                                       id: data['invoiceId'],
                                       expand: ['payment_intent']
                                     })

  render json: invoice
end

def retreive_upcoming_invoice
  data = JSON.parse request.body.read

  subscription = Stripe::Subscription.retrieve(
    data['subscriptionId']
  )

  invoice = Stripe::Invoice.upcoming(
    customer: data['customerId'],
    subscription: data['subscriptionId'],
    subscription_items: [
      {
        id: subscription.items.data[0].id,
        deleted: true
      },
      {
        price: ENV[data['newPriceId']],
        deleted: false
      }
    ]
  )

  render json: invoice
end

#Payment was successful.  Mark as paid in DB and update the stripe subscription id
def subscription_complete
  order = current_user.order_options[0]
  order.active = true
  order.save
end

def success
  @userId = current_user.id
end

def stripe_webhook
  # You can use webhooks to receive information about asynchronous payment events.
  # For more about our webhook events check out https://stripe.com/docs/webhooks.
  webhook_secret = Rails.application.credentials.webhook_secret
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
      head :bad_request
      return
    rescue Stripe::SignatureVerificationError => e
      # Invalid signature
      puts '⚠️  Webhook signature verification failed.'
      head :bad_request
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

  if event_type == 'invoice.payment_succeeded'
    # Used to provision services after the trial has ended.
    # The status of the invoice will show up as paid. Store the status in your
    # database to reference when a user accesses your service to avoid hitting rate
    # limits.
    # puts data_object
  end

  if event_type == 'invoice.payment_failed'
    # If the payment fails or the customer does not have a valid payment method,
    # an invoice.payment_failed event is sent, the subscription becomes past_due.
    # Use this webhook to notify your user that their payment has
    # failed and to retrieve new card details.
    # puts data_object
  end

  if event_type == 'invoice.finalized'
    # If you want to manually send out invoices to your customers
    # or store them locally to reference to avoid hitting Stripe rate limits.
    # puts data_object
  end

  if event_type == 'customer.subscription.deleted'
    # handle subscription cancelled automatically based
    # upon your subscription settings. Or if the user cancels it.
    # puts data_object
  end

  if event_type == 'customer.subscription.trial_will_end'
    # Send notification to your user that the trial will end
    # puts data_object
  end

  respond_to do |format|
    msg = { :status => 'success' }
    format.json { render :json => msg } 
  end
end

private 
  def signup_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, 
      shipping_addresses_attributes: [:address1, :address2, :city, :state, :postal],
      order_options_attributes: [:quality, :frequency, vehicle_id: []])
  end
end