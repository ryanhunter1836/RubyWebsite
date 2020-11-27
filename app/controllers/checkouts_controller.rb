class CheckoutsController < ApplicationController
include Vehicles

protect_from_forgery except: :stripe_webhook

#Renders the New Customer page.  Not actually bound to a model in this case
def new
  #Create a new shopping cart if this is a new customer
  if session[:shopping_cart].nil?
    @makes = get_makes
    cart = ShoppingCart.new
    @order_options = OrderOption.new

    if cart.save
      #Save the shopping cart ID in the session cookie
      session[:shopping_cart] = cart.id
    end

    @new_vehicle = true

  #Otherwise, retrieve the existing shopping cart
  else
    @makes = get_makes
    cart = ShoppingCart.find(session[:shopping_cart])
    @order_options = OrderOption.new
    @existing_vehicles = cart.order_options_ids.map { |id| OrderOption.find(id) }
    
    if(params[:newVehicle])
      @new_vehicle = true
    else
      @new_vehicle = false
    end
  end
end

#Create an order option entry          
def create
  #Only create the record if the submit tag is true
  if(params[:submit] == "true") 
    cart = ShoppingCart.find(session[:shopping_cart])

    #Only add the order if there are 2 or less existing orders in the cart
    if cart.order_options_ids.count < 3
      order = OrderOption.create(order_params)
      order.shipping = Shipping.new
      order.shipping.save
      
      if order.save!
        #Tie the order option to the cart
        cart.order_options_ids.append(order.id)
        cart.save
      end
    end
  end

  if params[:continue]
    redirect_to '/payments/new'
  else
    if (params[:new_vehicle])
      redirect_to '/checkouts/new?newVehicle=true'
    else
      redirect_to '/checkouts/new'
    end
  end
  
end

#Remove an order from the shopping cart
def destroy
  cart = ShoppingCart.find(session[:shopping_cart])
  order_id = params[:id]
  order = OrderOption.find(order_id)

  #Remove the order from the cart.  Rails doesn't think the record changed when simply deleting the order and saving
  order_ids = cart.order_options_ids.delete(order_id)
  if order_ids.nil?
    order_ids = []
  end

  cart.update_attribute(:order_options_ids, order_ids)
  puts "Removed order"

  #Delete the order
  order.destroy  

  msg = { success: true }
  render json: msg, status: 200
end

private 
  def order_params
    params.require(:order_option).permit(:vehicle_id, :quality, :frequency, :continue, :submit, :new_vehicle)
  end
end