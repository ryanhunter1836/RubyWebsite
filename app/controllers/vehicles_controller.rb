class VehiclesController < ApplicationController
    include Vehicles

    before_action :logged_in_user, only: [:edit, :update,:destroy]

    #Add vehicle to existing account
    def new
        @makes = get_makes
        @user = current_user
        @order_options = @user.order_options.build

        shipping = Stripe::Customer.retrieve(current_user.stripeCustomerId).shipping
        @shipping_address = ShippingAddress.new(
            address1: shipping.address.line1,
            address2: shipping.address.line2,
            city: shipping.address.city,
            state: shipping.address.state,
            postal: shipping.address.postal_code
        )
    end

    def create
        order = current_user.order_options.build(order_params['order_options_attributes']['0'])
        order.initialize_stripe_products

        # Create the subscription
        subscription = Stripe::Subscription.create(
            customer: current_user.stripeCustomerId,
            items: order.get_products_hash,
            default_tax_rates: [ 'txr_1HDKxXK9cC716JE2NSsbfS5r' ],
            expand: ['latest_invoice.payment_intent']
        )

        order.subscription_id = subscription.id
        order.add_subscription_ids(subscription)
        order.period_end = subscription.current_period_end
        order.save

        flash[:success] = "Subscription created!"
        redirect_to user_path(current_user.id)
    end

    def destroy
        order = current_user.order_options.find_by(id: params[:id])
        return redirect_to user_path(id: current_user.id) if order.nil?

        #Cancel the Stripe subscription
        Stripe::Subscription.delete(order.subscription_id)
        
        if order.destroy
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
        @order_option = @user.order_options.find_by(id: params[:id])
        return redirect_to user_path(id: current_user.id) if @order_option.nil?

        @makes = get_makes
        @models = Hash.new
        @years = Hash.new

        @order_option.vehicle_id.each_with_index do |vehicle_id, index|
            vehicle_details = get_vehicle_details(vehicle_id)
            @models[index] = get_models(vehicle_details[:make]).as_json
            @years[index] = get_years(vehicle_details[:make], vehicle_details[:model]).as_json
        end

        shipping = Stripe::Customer.retrieve(current_user.stripeCustomerId).shipping
        @shipping_address = ShippingAddress.new(
            address1: shipping.address.line1,
            address2: shipping.address.line2,
            city: shipping.address.city,
            state: shipping.address.state,
            postal: shipping.address.postal_code
        )
    end

    def update
        if current_user.update(order_params)
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
            params.require(:user).permit(shipping_addresses_attributes: [:id, :address1, :address2, :city, :state, :postal],
            order_options_attributes: [:id, :quality, :frequency, vehicle_id: []])
        end
    end
