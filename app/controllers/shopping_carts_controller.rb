class ShoppingCartsController < ApplicationController
    #Construct an order from the shopping cart
    def create
        current_order = current_shopping_cart.order_options.build(add_vehicle_params)
        current_order.save
        
        redirect_to checkouts_path
    end

    private 
        
        def add_vehicle_params
            params.require(:order_option).permit(:vehicle_id, :quality, :frequency)
        end
end
