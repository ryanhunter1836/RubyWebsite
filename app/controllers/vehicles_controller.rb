class VehiclesController < ApplicationController
    before_action :logged_in_user, only: [:edit, :update,:destroy]

    #Renders the New Customer page.  Not actually bound to a model in this case
    def new
        @makes = get_makes
        @user = User.new
        @user.shipping_addresses.build
        @user.order_options.build
    end

    def destroy
        order = current_user.order_option.find_by(id: params[:id])
        return redirect_to user_path(id: current_user.id) if order.nil?

        #Cancel the Stripe subscription
        Stripe::Subscription.delete(order.subscription_id)
        
        if order.destroy
            redirect_to users_path(current_user.id)
        else
            #Display an error page
            redirect_to users_path(current_user.id)
        end
    end

    def edit
        #Find the order through the user to verify the correct user is editing
        @user = current_user
        @order_option = @user.order_options.find_by(id: params[:id])
        return redirect_to user_path(id: current_user.id) if @order_option.nil?

        @makes = get_makes
        @models = Hash.new
        @years = Hash.new

        @order_option.vehicle_id.each_with_index do |vehicle_id, index|
            vehicle_details = get_vehicle_details(vehicle_id)
            @models[index] = get_models(vehicle_details[:make]).as_json
            @years[index] = get_years(vehicle_details[:make], vehicle_details[:model]).as_json
        end

        @shipping_address = @order_option.shipping_address
    end

    def update
        if current_user.update(order_params)
            flash[:success] = "Subscription updated successfully"
            redirect_to user_path(id: current_user.id)
        else
            #Render error page
        end
    end
    

    #Ajax calls
    def get_models_by_make
        make = Vehicle.find(params[:id]).make
        models = get_models(make)
        respond_to do |format|
            format.json { render :json => models }
        end
    end

    def get_years_by_model
        row = Vehicle.find(params[:id])
        make = row.make
        model = row.model
        years = get_years(make, model)
        respond_to do |format|
            format.json { render :json => years }
        end
    end

    private 

        def order_params
            params.require(:user).permit(shipping_addresses_attributes: [:id, :address1, :address2, :city, :state, :postal],
            order_options_attributes: [:id, :quality, :frequency, vehicle_id: []])
        end

        def add_vehicle_params
            params.require(:order_option).permit(:vehicle_id, :quality, :frequency)
        end

        def get_makes
            Vehicle.select('DISTINCT ON ("make") id, make')
        end

        def get_models(make)
            Vehicle.where(make: make).select('DISTINCT ON ("model") id, model')
        end

        def get_years(make, model)
            Vehicle.where(make: make, model: model).select('DISTINCT ON ("year") id, year')
        end

        def get_vehicle_details(vehicle_id)
            vehicle = Vehicle.find(vehicle_id)
            hash = {:make => vehicle.make, :model => vehicle.model, :year => vehicle.year}
        end

        def create_products_list(subscriptionIds)
            products = []
            current_user.order_options.each do |orderOption|
                #Subscription_id is a parallel list with subscription_item_id
                orderOption.stripe_product.each do |stripeProduct, index|
                    #Search through the list to see if the product has already been added
                    #If it has, increment the quantity
                    found = false
                    products.each do |product|
                        if(product[0] == stripeProduct)
                            product[1] += 1
                            #Add subscription item id to list
                            product[2] = subscriptionIds[index]
                            found = true
                        end
                    end

                    #Otherwise, add a new product to the list
                    if(!found)
                        products.push([stripeProduct, 1])
                    end
                end
            end

            #Create a map of the products
            productsMap = []
            products.each do |item|
                productsMap.append({ id: item[2], price: item[0], quantity: item[1] })
            end

            productsMap
        end
    end
