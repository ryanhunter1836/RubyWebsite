module ShoppingCartsHelper

    #Returns the current shopping cart
    def current_shopping_cart
        if logged_in?
            #Create a new shopping cart
            if current_user.shopping_cart.nil?
                current_user.shopping_cart = ShoppingCart.create
                @current_shopping_cart = current_user.shopping_cart
            else
                @current_shopping_cart ||= current_user.shopping_cart
            end
        #User is shopping anonymously
        else
            #Check if there is already a shopping cart associated with this session
            if session[:shopping_cart]
                @current_shopping_cart ||= ShoppingCart.find(session[:shopping_cart])
            #If not, create a new cart and associate it with this session
            else
                @current_shopping_cart = ShoppingCart.create
                session[:shopping_cart] = @current_shopping_cart.id
                @current_shopping_cart
            end
        end
    end
end
