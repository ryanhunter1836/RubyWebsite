class VehiclesController < ApplicationController
    before_action :logged_in_user, only: [:new, :create, :edit, :update]

    #Renders the 'new' page.  Not actually bound to a model in this case
    def new
        @makes = Vehicle.select(:id,:make).group(:id,:make)
        @order = OrderOption.new
        @order_options = current_shopping_cart.order_options.all
    end

    #Recieves the form results.  Adds the vehicle to the shopping cart then renders the add vehicle page again
    def create
        @order = current_shopping_cart.order_options.build(add_vehicle_params)
        if @order.save!
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
            params.require(:order_option).permit(:vehicle_id, :quality, :frequency, :user_id)
        end
end
