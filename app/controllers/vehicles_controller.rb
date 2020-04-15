class VehiclesController < ApplicationController

    #Renders the 'new' page.  Not actually bound to a model in this case
    def new
        @makes = Vehicle.select(:id,:make).group(:id,:make)
        @order_option = OrderOption.new
    end

    #Recieves the form results
    def create
        @order_option = current_user.order_options.build(add_vehicle_params)
        if @order_option.save!
            flash[:info] = "Successfully added vehicle"
        else
            flash[:danger] = "Could not save"
        end
        redirect_to users_path
    end

    def edit
    end

    def delete
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
