class VehiclesController < ApplicationController
    before_action :logged_in_user, only: [:edit, :update]

    #Renders the 'new' page.  Not actually bound to a model in this case
    def new
        @makes = Vehicle.select(:id,:make).group(:id,:make)
        @order = OrderOption.new
        @order_options = current_shopping_cart.order_options.all
    end

    #Recieves the form results.  Adds the vehicle to the shopping cart then renders the add vehicle page again
    def create
        current_order = current_shopping_cart.order_options.build(add_vehicle_params)
        if current_order.save
            flash[:info] = "Successfully added vehicle"
        else
            flash[:danger] = "Could not add vehicle"
        end

        @makes = Vehicle.select(:id,:make).group(:id,:make)
        @order_option = OrderOption.new
        @shopping_cart = current_shopping_cart.order_options.all
        
        redirect_to new_vehicle_path
    end

    def edit
    end

    #Ajax calls
    def get_models_by_make
        make = Vehicle.find(params[:id]).make
        @models = Vehicle.where(make: make).distinct
        respond_to do |format|
            format.json { render :json => @models }
        end
    end

    def get_years_by_model
        row = Vehicle.find(params[:id])
        make = row.make
        model = row.model
        @years = Vehicle.where(make: make, model: model).distinct
        respond_to do |format|
            format.json { render :json => @years }
        end
    end

    private 
        
        def add_vehicle_params
            params.require(:order_option).permit(:vehicle_id, :quality, :frequency)
        end

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
