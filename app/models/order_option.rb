class OrderOption < ApplicationRecord
    include ActiveModel::Dirty

    belongs_to :user
    has_one :shipping_address
    accepts_nested_attributes_for :shipping_address
    after_create :update_next_delivery
    before_save :update_subscription, if: :will_save_change_to_vehicle_id?

    enum frequency: [ :six_months, :one_year ]
    enum quality: [ :good, :better, :best ]

    #Generates hash of Stripe products and their quantities
    def initialize_stripe_products
        self.stripe_products = Hash.new
        self.vehicle_id.each do |id|
            products = get_stripe_products_for_vehicle(id)

            #Create hash of Stripe products
            if stripe_products.key?(products[:driver_front].stripe_id)
                stripe_products[products[:driver_front].stripe_id][:quantity] += 1
            else
                stripe_products[products[:driver_front].stripe_id] = { quantity: 1, subscription_id: nil }
            end

            #Calculate total price
            self.total_price = products[:driver_front].price

            if !products[:passenger_front].nil?
                if stripe_products.key?(products[:passenger_front].stripe_id)
                    stripe_products[products[:passenger_front].stripe_id][:quantity] += 1
                else
                    stripe_products[products[:passenger_front].stripe_id] = { quantity: 1, subscription_id: nil }
                end

                self.total_price = products[:passenger_front].price
            end

            if !products[:rear].nil?
                if stripe_products.key?(products[:rear].stripe_id)
                    stripe_products[products[:rear].stripe_id][:quantity] += 1
                else
                    stripe_products[products[:rear].stripe_id] = { quantity: 1, subscription_id: nil }
                end

                self.total_price += products[:rear].price
            end
        end
    end

    #Tie the Stripe products to their subscription IDs
    def add_subscription_ids(subscription)
        self.stripe_products.each do |key, value|
            subscription.items.data.each do |data|
                if(data.price.id == key)
                    value[:subscription_id] = data.id
                end
            end 
        end
    end

    def get_products_hash
        #Create a hash of the products
        productsMap = []
        self.stripe_products.each do |key, value|
            productsMap.append({ price: key, quantity: value["quantity"] })
        end
        productsMap
    end

private

    def get_stripe_products_for_vehicle(vehicle_id)
        #Get the associated stripe product for the vehicle and parameters
        vehicle = Vehicle.find(vehicle_id)
        driver_front = StripeProduct.where(size: vehicle.driver_front, quality: OrderOption.qualities[self.quality] , frequency: OrderOption.frequencies[self.frequency]).first
        passenger_front = StripeProduct.where(size: vehicle.passenger_front, quality: OrderOption.qualities[self.quality], frequency: OrderOption.frequencies[self.frequency]).first
        rear = StripeProduct.where(size: vehicle.rear, quality: OrderOption.qualities[self.quality], frequency: OrderOption.frequencies[self.frequency]).first
        return { driver_front: driver_front, passenger_front: passenger_front, rear: rear }
    end

    def update_next_delivery
        if (self.six_months?)
            self.next_delivery = DateTime.now + 6.months
        else
            self.next_delivery = DateTime.now + 12.months
        end
    end

    def update_subscription
        unless vehicle_id_change_to_be_saved[0].blank?
            changed_vehicles_list = get_changed_vehicles_list
            stripe_changes = calculate_stripe_changes(changed_vehicles_list)

            #Update the subscription
            products_map = []
            stripe_changes[:new].each do |stripe_id|
                products_map.append({ price: stripe_id, quantity: stripe_products[stripe_id]["quantity"] })
            end

            stripe_changes[:deleted].each do |stripe_id|
                products_map.append({ id: stripe_products[stripe_id]["subscription_id"], deleted: true })
                stripe_products.delete(stripe_id)
            end

            stripe_changes[:updated].each do |stripe_id|
                products_map.append({ id: stripe_products[stripe_id]["subscription_id"], quantity: stripe_products[stripe_id]["quantity"] })
            end

            if !products_map.blank?
                #Update the quantity of remaining products
                updated_subscription = Stripe::Subscription.update(
                    self.subscription_id,
                    items: products_map,
                    proration_behavior: 'none',
                )

                #Update the database with the new subscription
                add_subscription_ids(updated_subscription)
            end
        end
    end

    def get_changed_vehicles_list
        same_vehicles = []
        new_vehicles = vehicle_id_change_to_be_saved[1].clone
        removed_vehicles = []

        #vehicle_id_change_to_be_saved[0] = old vehicles
        #vehicle_id_change_to_be_saved[1] = new vehicles
        #Check which vehicles have been added, removed, or are the same
        vehicle_id_change_to_be_saved[0].each do |old_vehicle_id|
            found = false
            vehicle_id_change_to_be_saved[1].each do |new_vehicle_id|
                if(old_vehicle_id == new_vehicle_id)
                    same_vehicles.append(old_vehicle_id)
                    new_vehicles.delete(new_vehicle_id)
                    found = true
                    break
                end
            end
            if(!found)
                removed_vehicles.append(old_vehicle_id)
            end
        end

        return { same: same_vehicles, new: new_vehicles, removed: removed_vehicles }
    end

    #Return a hash of the changes in Stripe products
    def calculate_stripe_changes(changed_vehicles_list)
        new_products = []
        updated_products = []
        deleted_products = []

        #Add the Stripe products of the new vehicles
        changed_vehicles_list[:new].each do |id|
            products = get_stripe_products_for_vehicle(id)
            driver_front = products[:driver_front].stripe_id

            if stripe_products.key?(driver_front)
                #The database saves the hash as a JSON type, so have to use strings instead of symbols for keys when accessing object
                stripe_products[driver_front]["quantity"] += 1
                updated_products.append(driver_front)
            else
                stripe_products[driver_front] = { "quantity" => 1, "subscription_id" => nil }
                new_products.append(driver_front)
            end

            self.total_price += products[:driver_front].price

            #Some supercars only have 1 wiper blade
            if !products[:passenger_front].nil?
                passenger_front = products[:passenger_front].stripe_id

                if stripe_products.key?(passenger_front)
                    stripe_products[passenger_front]["quantity"] += 1

                    if (!updated_products.include?(passenger_front) && !new_products.include?(passenger_front))
                        updated_products.append(passenger_front)
                    end
                else
                    stripe_products[passenger_front] = { "quantity" => 1, "subscription_id" => nil }
                    new_products.append(passenger_front)
                end

                self.total_price += products[:passenger_front].price
            end

            if !products[:rear].nil?
                rear = products[:rear].stripe_id

                if stripe_products.key?(rear)
                    stripe_products[rear]["quantity"] += 1

                    if (!updated_products.include?(rear) && !new_products.include?(rear))
                        updated_products.append(rear)
                    end
                else
                    stripe_products[rear] = { "quantity" => 1, "subscription_id" => nil }
                    new_products.append(rear)
                end

                self.total_price += products[:rear].price
            end
        end

        #Remove the Stripe products of the removed vehicles
        changed_vehicles_list[:removed].each do |id|
            products = get_stripe_products_for_vehicle(id)
            driver_front = products[:driver_front].stripe_id

            #Update hash of Stripe products
            if stripe_products[driver_front]["quantity"] == 1
                deleted_products.append(driver_front)

                if updated_products.include?(driver_front)
                    updated_products.delete(driver_front)
                end
            else
                stripe_products[driver_front]["quantity"] -= 1

                if !updated_products.include?(driver_front)
                    updated_products.append(driver_front)
                end
            end

            self.total_price -= products[:driver_front].price

            if !products[:passenger_front].nil?
                passenger_front = products[:passenger_front].stripe_id

                if stripe_products[passenger_front]["quantity"] == 1
                    deleted_products.append(passenger_front)

                    if updated_products.include?(passenger_front)
                        updated_products.delete(passenger_front)
                    end
                else
                    stripe_products[passenger_front]["quantity"] -= 1

                    if !updated_products.include?(passenger_front)
                        updated_products.append(passenger_front)
                    end
                end

                self.total_price -= products[:passenger_front].price
            end


            if !products[:rear].nil?
                rear = products[:rear].stripe_id

                if stripe_products[rear]["quantity"] == 1

                    if updated_products.include?(rear)
                        updated_products.delete(rear)
                    end

                    deleted_products.append(rear)
                else
                    stripe_products[rear]["quantity"] -= 1

                    if !updated_products.include?(rear)
                        updated_products.append(rear)
                    end
                end

                self.total_price -= products[:rear].price
            end
        end

        return { new: new_products, updated: updated_products, deleted: deleted_products }
    end
end