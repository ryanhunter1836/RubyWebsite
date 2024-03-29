class VehiclesController < ApplicationController
    include Vehicles

    before_action :logged_in_user, only: [:new, :create, :edit, :update, :destroy]

    #Add vehicle to existing account
    def new
        @makes = get_makes
        @order_options = OrderOption.new
        @user_id = current_user.id

        shipping = Stripe::Customer.retrieve(current_user.stripe_customer_id).shipping
        @shipping_address = ShippingAddress.new(
            address1: shipping.address.line1,
            address2: shipping.address.line2,
            city: shipping.address.city,
            state: shipping.address.state,
            postal: shipping.address.postal_code
        )
    end

    def create
        order = OrderOption.create(order_params)
        order.shippings.create(scheduled_date: DateTime.now, paid: true)

        # Create the subscription
        subscription = Stripe::Subscription.create(
            customer: current_user.stripe_customer_id,
            items: order.get_products_hash,
            default_tax_rates: [ 'txr_1HDKxXK9cC716JE2NSsbfS5r' ],
            expand: ['latest_invoice.payment_intent']
        )

        order.user_id = current_user.id
        order.subscription_id = subscription.id
        order.add_subscription_ids(subscription)
        order.cycle_anchor = subscription.current_period_start
        order.active = true

        if order.save 
            UserMailer.subscription_addition(current_user).deliver_now
            flash[:success] = "Subscription created!"
            redirect_to user_path(current_user.id)
        end
    end

    def destroy
        order = current_user.order_options.find_by(id: params[:id])
        vehicle_id = order.vehicle_id
        return redirect_to user_path(id: current_user.id) if order.nil?

        #Cancel the Stripe subscription
        Stripe::Subscription.delete(order.subscription_id)

        #Delete the upcoming order unless it has already shipped for some reason
        shipment = order.shippings.all.order(scheduled_date: :desc).first
        if !shipment.nil? && shipment.shipped == false
            shipment.destroy
        end

        order_copy = order.clone
        if order.destroy
            #Send a confirmation email
            UserMailer.subscription_cancel(current_user, order_copy).deliver_now
            flash[:success] = "Subscription cancelled"
            redirect_to user_path(current_user.id)
        else
            #Display an error page
            flash[:danger] = "Error occured and subscription could not be cancelled"
            redirect_to user_path(current_user.id)
        end
    end

    def edit
        #Find the order through the user to verify the correct user is editing
        @user = current_user
        @order_options = @user.order_options.find_by(id: params[:id])
        return redirect_to user_path(id: current_user.id) if @order_options.nil?

        @makes = get_makes

        vehicle_details = get_vehicle_details(@order_options.vehicle_id)
        @models = get_models(vehicle_details[:make]).as_json
        @years = get_years(vehicle_details[:make], vehicle_details[:model]).as_json

        shipping = Stripe::Customer.retrieve(current_user.stripe_customer_id).shipping
        @shipping_address = ShippingAddress.new(
            address1: shipping.address.line1,
            address2: shipping.address.line2,
            city: shipping.address.city,
            state: shipping.address.state,
            postal: shipping.address.postal_code
        )
        paymentMethod = Stripe::PaymentMethod.retrieve(@user.payment_method_id)
        @billing_address = {
        address1: paymentMethod.billing_details.address.line1,
        address2: paymentMethod.billing_details.address.line2,
        city: paymentMethod.billing_details.address.city,
        state: paymentMethod.billing_details.address.state,
        postal: paymentMethod.billing_details.address.postal_code
        }
    end

    def update
        order_options = current_user.order_options.find_by(id: params[:id])
        if order_options.update(order_params)          
            #Send an email confirming the update
            UserMailer.subscription_change(current_user).deliver_now
            flash[:success] = "Subscription updated successfully"
            redirect_to user_path(id: current_user.id)
        else
            #Render error page
        end
    end

    #Ajax calls
    def get_models_by_make
        make = Vehicle.find(params[:id]).make
        models = get_models(make)
        respond_to do |format|
            format.json { render :json => models }
        end
    end

    def get_years_by_model
        row = Vehicle.find(params[:id])
        make = row.make
        model = row.model
        years = get_years(make, model)
        respond_to do |format|
            format.json { render :json => years }
        end
    end

    private
     
    def order_params
        params.require(:order_option).permit(:vehicle_id, :wipertype, :frequency, :continue)
    end
end
