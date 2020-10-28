class CheckoutsController < ApplicationController
include Vehicles

protect_from_forgery except: :stripe_webhook

#Renders the New Customer page.  Not actually bound to a model in this case
def new
  if session[:shopping_cart].nil?
    @makes = get_makes
    cart = ShoppingCart.new
    @order_options = OrderOption.new

    if cart.save
      #Save the shopping cart ID in the session cookie
      session[:shopping_cart] = cart.id
    end

  #Otherwise, retrieve the existing shopping cart
  else
    @makes = get_makes
    cart = ShoppingCart.find(session[:shopping_cart])
    @order_options = OrderOption.new
    @existing_vehicles = cart.order_options_ids.map { |id| OrderOption.find(id) }
  end
end

#Create an order option entry          
def create
  cart = ShoppingCart.find(session[:shopping_cart])
  order = OrderOption.create(order_params)
  order.shipping = Shipping.new
  order.shipping.save
  
  if order.save!
    #Tie the order option to the cart
    cart.order_options_ids.append(order.id)
    cart.save
  end

  if params[:continue]
    redirect_to '/payments/new'
  else
    redirect_to '/checkouts/new'
  end
  
end

private 
  def order_params
    params.require(:order_option).permit(:vehicle_id, :quality, :frequency, :continue)
  end
end