class CheckoutsController < ApplicationController
include Vehicles

protect_from_forgery except: :stripe_webhook

#Renders the New Customer page.  Not actually bound to a model in this case
def new
  @makes = get_makes
  @user = User.new
  @order_options = @user.order_options.build
  @shipping_address = ShippingAddress.new
end

#Create the user account             
def create
  existing_user = User.find_by(email: params[:user][:email])

  #Update an existing record
  if (!existing_user.nil? && existing_user.accountCreated == false)
    msg = nil
    existing_user.assign_attributes(signup_params)

    address = ShippingAddress.new(shipping_params)
    address.valid?

    if existing_user.valid? && address.valid?
      existing_user.save
      msg = { success: true, user_id: existing_user.id }
    else
      msg = { success: false, user: existing_user.errors, address: address.errors }
    end

    render json: msg, status: 200
  #Create a new record
  else
    msg = nil
    new_user = User.create(signup_params)
    new_user.accountCreated = false

    address = ShippingAddress.new(shipping_params)
    address.valid?

    if new_user.valid? && address.valid?
      new_user.save
      msg = { success: true, user_id: new_user.id }
    else
      msg = { success: false, user: new_user.errors, address: address.errors }
    end

    render json: msg, status: 200
  end  
end

def setup
  respond_to do |format|
    msg = { :publishableKey => Rails.application.credentials.publishable_key }
    format.json { render :json => msg } 
  end
end

def create_customer
  data = JSON.parse request.body.read
  user = User.find(data['user_id'])

  if !user.nil?
    customer = Stripe::Customer.create(
      email: user.email,
      name: user.name,
      shipping: {
        address:
        {
          line1: data['address1'],
          line2: data['address2'],
          city: data['city'],
          state: data['state'],
          postal_code: data['postal']
        },
        name: user.name
      }
    )
  
    user.stripeCustomerId = customer.id
    user.save
  
    respond_to do |format|
      msg = { :customer => customer, :name => user.name }
      format.json { render :json => msg } 
    end
  else
  end
end

#Create a subscription for the customer
def create_subscription
  data = JSON.parse request.body.read
  user = User.find(data['user_id'])

  if !user.nil?
    order = user.order_options[0]

    order.initialize_stripe_products

    begin
      Stripe::PaymentMethod.attach(
        data['paymentMethodId'],
        { customer: data['customerId'] }
      )
    rescue Stripe::CardError => e
      halt 200, { 'Content-Type' => 'application/json' }, { 'error': { message: e.error.message } }.to_json
    end

    #Save the payment id to the user
    user.paymentMethodId = data['paymentMethodId']
    user.save

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
      items: order.get_products_hash,
      default_tax_rates: [ 'txr_1HDKxXK9cC716JE2NSsbfS5r' ],
      expand: ['latest_invoice.payment_intent']
    )

    order.subscription_id = subscription.id
    order.add_subscription_ids(subscription)
    order.period_end = subscription.current_period_end
    order.active = true
    order.save

    render json: subscription
  end
end

#Payment was successful.  Mark as paid in DB and update the stripe subscription id
def subscription_complete
  user = User.find(params[:id])

  if !user.nil?
    user.accountCreated = true
    user.save
    #user.send_activation_email

    log_in user
    @userId = user.id
    head 200
  else
    head 500
  end
end

def success
  user = User.find(params[:id])
  log_in user
  @userId = user.id
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
  msg = ''

  if event_type == 'invoice.payment_succeeded'
    puts data_object

    # Used to provision services after the trial has ended.
    # The status of the invoice will show up as paid. Store the status in your
    # database to reference when a user accesses your service to avoid hitting rate
    # limits.
    user = User.find_by(stripeCustomerId: data_object.customer)

    if !user.nil?
      #Find the subscription 
      order = user.order_options.find_by(subscription_id: data_object.data.subscription)
      if !order.nil?
        order.period_end = data_object.period_end
        order.save
        msg = { status: 200 }
      else
        msg = { status: 400 }
      end
      
    else
      #Return an error
      msg = { status: 400 }
    end
  end

  if event_type == 'invoice.payment_failed'
    # If the payment fails or the customer does not have a valid payment method,
    # an invoice.payment_failed event is sent, the subscription becomes past_due.
    # Use this webhook to notify your user that their payment has
    # failed and to retrieve new card details.
    # puts data_object
  end

  if event_type == 'invoice.upcoming'
    #Send a notification email to customer and admin
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
    format.json { render :json => msg } 
  end
end

private 
  def signup_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, 
      order_options_attributes: [:quality, :frequency, vehicle_id: []])
  end

  def shipping_params
    params.require(:shipping_address).permit(:address1, :address2, :city, :state, :postal)
  end
end