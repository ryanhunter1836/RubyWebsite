class CheckoutsController < ApplicationController
protect_from_forgery except: :stripe_webhook

#Create the user account             
def create
  @user = User.create(signup_params)

  #Need to save the shipping address to the order as well
  if @user.save
    @user.send_activation_email

    #Log in the user for use in the Stripe payment
    log_in @user
  end
  render json: @user.errors
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
    items: create_products_list,
    expand: ['latest_invoice.payment_intent']
  )

  #Save the subscription id to the order options
  current_user.order_options.each do |f|
    f.subscription_id = subscription.id
    f.subscription_item_id = getSubscriptionIdList(f, subscription)
    f.save
  end

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

def retreive_customer_payment_method
  data = JSON.parse request.body.read

  payment_method = Stripe::PaymentMethod.retrieve(
    data['paymentMethodId']
  )

  render json: payment_method
end

#Payment was successful.  Mark as paid in DB and update the stripe subscription id
def subscription_complete
  current_user.order_options[0].active = true
  #Redirect to thank you page
  flash[:success] = "Thank you for your order!"
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
  def getSubscriptionIdList(orderOption, subscription)
    subscriptionIds = []
    #Loop through all the data items and find the one that matches the price ID
    orderOption.stripe_product.each do |stripeProduct|
      subscription.items.data.each do |item|
        if(item.price.id == stripeProduct)
          subscriptionIds.append(item.id)
        end
      end
    end

    subscriptionIds
  end

  def calculate_total_price(order_options)
    totalPrice = 0
    order_options.each do |t|
      totalPrice += t.total_price
    end
    totalPrice
  end

  def signup_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, 
      shipping_addresses_attributes: [:address1, :address2, :city, :state, :postal],
      order_options_attributes: [:quality, :frequency, vehicle_id: []])
  end

  #Method to create list of products user is subscribing to
  def create_products_list
    products = []
    current_user.order_options.each do |f|
    f.stripe_product.each do |g|
        #Search through the list to see if the product has already been added
        #If it has, increment the quantity
        found = false
        products.each do |h|
          if(h[0] == g)
              h[1] += 1
              found = true
          end
        end

        #Otherwise, add a new product to the list
        if(!found)
          products.push([g, 1])
        end
      end
    end

    #Create a map of the products
    productsMap = []
    products.each do |item|
      productsMap.append({ price: item[0], quantity: item[1] })
    end

    productsMap
  end
end