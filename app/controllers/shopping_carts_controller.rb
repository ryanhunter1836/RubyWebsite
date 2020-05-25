class ShoppingCartsController < ApplicationController
    before_action :logged_in_user,  only: [:create]
    #Recieves the form results.  Takes the shopping cart then moves to the checkout page
    def create
        flash[:success] = "Submitted shopping cart"
        redirect_to user_path(current_user.id)
    end
end
