module Vehicles
    extend ActiveSupport::Concern

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