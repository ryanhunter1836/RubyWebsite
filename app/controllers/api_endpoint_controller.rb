class ApiEndpointController < ApplicationController
  include VehicleHelper

  def query_user
      user = User.find_by(email: params[:email])
  
      if user.nil? || user.admin?
        respond_to do |format|
          msg = { :success => false }
          format.json { render :json => msg } 
        end
        return 
      else
        #Get the user's shipping address
        shipping = Stripe::Customer.retrieve(user.stripe_customer_id).shipping
        address = ShippingAddress.new(
          address1: shipping.address.line1,
          address2: shipping.address.line2,
          city: shipping.address.city,
          state: shipping.address.state,
          postal: shipping.address.postal_code
        )
  
        formatted_orders = []
        orders = user.order_options.all
        orders.each do |order|
          options = Hash.new
          options[:frequency] = get_frequency_string(order.frequency)
          options[:quality] = get_quality_string(order.quality)
          options[:total_price] = pretty_amount(order.total_price)
          options[:subscription_id] = order.subscription_id
          options[:vehicle_id] = get_vehicle_name(order.vehicle_id)
          options[:cycle_anchor] = epoch_to_datetime(order.cycle_anchor).to_datetime.in_time_zone("Central Time (US & Canada)")
          options[:next_shipment_date] = Time.at(order.next_shipment_date).to_datetime.in_time_zone("Central Time (US & Canada)").strftime("%m/%d/%Y")
          formatted_orders.append(options)
        end
  
        #Remove the password and other sensitive fields from the user
        redacted_user = User.new
        redacted_user.id = user.id
        redacted_user.name = user.name
        redacted_user.email = user.email
        redacted_user.activated = user.activated
        redacted_user.activated_at = user.activated_at
        redacted_user.stripe_customer_id = user.stripe_customer_id

        respond_to do |format|
          msg = { :success => true, :user_info => redacted_user, :orders => formatted_orders, :shipping => address }
          format.json { render :json => msg } 
        end
      end
    end

    def query_vehicle
      vehicle = Vehicle.find(params[:id].to_i)
      
      if(vehicle.nil?)
        respond_to do |format|
          msg = { :success => false }
          format.json { render :json => msg } 
          return 
        end
      else
        respond_to do |format|
          msg = { :success => true, :vehicle => vehicle }
          format.json { render :json => msg}
        end
      end
    end

    def save_order_status
      data = JSON.parse request.body.read

      changes = data['changes']
      #Save the change to the shipping info
      changes.each do |change|
        order = OrderOption.find(change['id'].to_i)
        shipping = order.shipping
        shipping.shipped_at = DateTime.now
        shipping.save!

        if(change['complete'])
          #Update the next shipment date of the parent order
          order.next_shipment_date = Time.at(order.cycle_anchor) + (order.frequency == 'six_months' ? 6.month : 1.year)
          order.save
        end
      end
    end
end
