class ShoppingCartsController < ApplicationController
    before_action :logged_in_user,  only: [:create]
    #Converts the shopping cart into an order
    def create
        puts("Received shopping cart")
        head :ok
    end
end
