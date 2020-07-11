class VehiclesController < ApplicationController
    before_action :logged_in_user, only: [:edit, :update]

    #Renders the 'new' page.  Not actually bound to a model in this case
    def new
        @makes = Vehicle.select(:id,:make).group(:id,:make)
        @user = User.new
        @user.shipping_addresses.build
        @user.order_options.build
    end

    def destroy
        #Remove the order option from the database and cancel the stripe subscription
        order = OrderOption.find(params[:id])
        subscriptionId = order.subscription_id
        
        if order.destroy
            if(current_user.order_options.count == 0)
                #If there are no more vehicles left, cancel the subscription
                deleted_subscription = Stripe::Subscription.delete(subscriptionId)

            else
                subscription = Stripe::Subscription.retrieve(subscriptionId)

                #Otherwise, update the subscription
                updated_subscription = Stripe::Subscription.update(
                    subscriptionId,
                    cancel_at_period_end: false,
                    items: create_products_list(order.subscription_item_id)
                )
            end

            redirect_to users_path(current_user.id)
        else
            redirect_to users_path(current_user.id)
        end
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
