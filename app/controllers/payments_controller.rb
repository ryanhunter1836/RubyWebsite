class PaymentsController < ApplicationController
    include ActionView::Helpers::NumberHelper
    include PaymentsHelper
    
    def new
        @user = User.new

        cart = ShoppingCart.find(session[:shopping_cart])
        @selected_vehicles = cart.order_options_ids.map { |id| OrderOption.find(id) }
        
        @total_price = 0
        @selected_vehicles.each do |order|
            @total_price += order.total_price
        end

        @total_price = calc_total_price(@total_price)
    end

    def create
        email = params[:user][:email].downcase
        existing_user = User.find_by(email: email)

        #Update an existing record
        if (!existing_user.nil? && existing_user.account_created == false)
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
            new_user = User.new(signup_params)
            new_user.account_created = false

            address = ShippingAddress.new(shipping_params)
            address.valid?

            if address.valid? && new_user.save
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
            phone: data['phone'],
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
        
            user.stripe_customer_id = customer.id
            user.save

            #Assign all the items in the shopping cart to the user
            cart = ShoppingCart.find(session[:shopping_cart])
            cart.order_options_ids.each do |id|
                order = OrderOption.find(id)
                order.user_id = user.id 
                #Create a shipment item for each product
                order.shippings.create(scheduled_date: DateTime.now, paid: true)
                order.save
            end

            #Delete the shopping cart
            ShoppingCart.delete(cart.id)
        
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
            begin
                Stripe::PaymentMethod.attach(
                    data['paymentMethodId'],
                    { customer: data['customerId'] }
                )
                rescue Stripe::CardError => e
                halt 200, { 'Content-Type' => 'application/json' }, { 'error': { message: e.error.message } }.to_json
            end

        
            #Save the payment id to the user
            user.payment_method_id = data['paymentMethodId']
            user.save
        
            # Set the default payment method on the customer
            Stripe::Customer.update(
            data['customerId'],
            invoice_settings: {
                default_payment_method: data['paymentMethodId']
            }
            )

            user.order_options.each do |order|
                # Create the subscription
                subscription = Stripe::Subscription.create(
                    customer: data['customerId'],
                    items: order.get_products_hash,
                    default_tax_rates: [ 'txr_1HDKxXK9cC716JE2NSsbfS5r' ],
                    expand: ['latest_invoice.payment_intent']
                )
            
                order.subscription_id = subscription.id
                order.add_subscription_ids(subscription)
                order.cycle_anchor = subscription.current_period_start
                order.active = true
                order.save

                order.add_payment_intent(subscription)
            end
        
            head 200
        end
    end
    
    #Payment was successful.  Mark as paid in DB and update the stripe subscription id
    def subscription_complete
    user = User.find(params[:id])
    
    if !user.nil?
        user.account_created = true
        user.save
        user.send_activation_email
    
        log_in user
        @userId = user.id
        head 200
    else
        head 500
    end
    end
    
    def success
        session[:shopping_cart] = nil
    end

    private 	
    def signup_params	
        params.require(:user).permit(:name, :email, :password, :password_confirmation, 	
        order_options_attributes: [:wipertype, :frequency, vehicle_id: []])	
    end	

    def shipping_params	
        params.require(:shipping_address).permit(:address1, :address2, :city, :state, :postal, :phone)
    end
end
