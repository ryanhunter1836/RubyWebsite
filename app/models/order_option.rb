class OrderOption < ApplicationRecord
    include ActiveModel::Dirty

    belongs_to :user, optional: true
    has_many :shippings
    before_save :update_subscription
    before_save :initialize_stripe_products
    after_save :update_shipping_dates, if: :saved_change_to_frequency?

    enum frequency: [ :six_months, :one_year ]
    enum quality: [ :good, :better, :best ]

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

    def get_next_shipment_date
        #Find the shipment object that has the next shipment date
        # date = Shipping.where(order_option_id: self.id).where('scheduled_date > ?', DateTime.now).first
        date = self.shippings.where('scheduled_date > ?', DateTime.now).first

        if date.nil?
            #If the date is null, calculate the next scheduled delivery
            if frequency == 'six_months'
                date = (Time.at(self.cycle_anchor) + 6.month).to_datetime.in_time_zone("Central Time (US & Canada)").strftime("%m/%d/%Y")
            else
                date = (Time.at(self.cycle_anchor) + 1.year).to_datetime.in_time_zone("Central Time (US & Canada)").strftime("%m/%d/%Y")
            end
            # date = "null date"
        else
            date = date.scheduled_date.to_datetime.in_time_zone("Central Time (US & Canada)").strftime("%m/%d/%Y")
        end

        return date
    end

    def add_payment_intent(subscription)
        #Find the shipping object
        shipping = self.shippings.first
        shipping.update(payment_intent_id: subscription.latest_invoice.payment_intent.id)
    end

private
    #Generates hash of Stripe products and their quantities
    def initialize_stripe_products
        if self.stripe_products.empty?
            self.stripe_products = Hash.new
            products = get_stripe_products_for_vehicle(self.vehicle_id)

            #Create hash of Stripe products
            if stripe_products.key?(products[:driver_front].stripe_id)
                stripe_products[products[:driver_front].stripe_id]["quantity"] += 1
            else
                stripe_products[products[:driver_front].stripe_id] = { "quantity" => 1, "subscription_id" => nil }
            end

            #Calculate total price
            self.total_price = products[:driver_front].price

            if !products[:passenger_front].nil?
                if stripe_products.key?(products[:passenger_front].stripe_id)
                    stripe_products[products[:passenger_front].stripe_id]["quantity"] += 1
                else
                    stripe_products[products[:passenger_front].stripe_id] = { "quantity" => 1, "subscription_id" => nil }
                end

                self.total_price += products[:passenger_front].price
            end

            if !products[:rear].nil?
                if stripe_products.key?(products[:rear].stripe_id)
                    stripe_products[products[:rear].stripe_id]["quantity"] += 1
                else
                    stripe_products[products[:rear].stripe_id] = { "quantity" => 1, "subscription_id" => nil }
                end

                self.total_price += products[:rear].price
            end
        end
    end

    def get_stripe_products_for_vehicle(vehicle_id)
        #Get the associated stripe product for the vehicle and parameters
        vehicle = Vehicle.find(vehicle_id)
        driver_front = StripeProduct.where(size: vehicle.driver_front, quality: OrderOption.qualities[self.quality] , frequency: OrderOption.frequencies[self.frequency]).first
        passenger_front = StripeProduct.where(size: vehicle.passenger_front, quality: OrderOption.qualities[self.quality], frequency: OrderOption.frequencies[self.frequency]).first
        rear = StripeProduct.where(size: vehicle.rear, quality: OrderOption.qualities[self.quality], frequency: OrderOption.frequencies[self.frequency]).first
        return { driver_front: driver_front, passenger_front: passenger_front, rear: rear }
    end

    def update_subscription
        #Only update if this subscription is already active
        if (self.active && !active_changed? && !self.stripe_products.empty?)
            changes = calculate_stripe_changes

            #Key is Stripe product ID, value is a hash of quantity and subscription_id
            products_map = []
            #Remove the old products from the subscription
            changes[:deleted].each do |key, value|
                products_map.append({ id: value['subscription_id'], deleted: true })
                stripe_products.delete(key)
            end
    
            #Add the new products to the subscription
            changes[:new].each do |key, value|
                products_map.append({ price: key, quantity: value['quantity'] })
                stripe_products[key] = value
            end
    
            #Update the quantity of remaining products
            changes[:updated].each do |key, value|
                products_map.append({ id: value['subscription_id'], quantity: value['quantity']})
                stripe_products[key]['quantity'] = value['quantity']
            end
    
            if !products_map.blank?
                updated_subscription = Stripe::Subscription.update(
                    self.subscription_id,
                    items: products_map,
                    proration_behavior: 'none',
                    #The trial end has to be set to when the user should be billed again
                    #Otherwise, Stripe will immediately bill them as if they started a new subscription
                    trial_end: self.cycle_anchor + (self.frequency == 'six_months' ? 6.month : 1.year)
                )
    
                #Update the database with the new subscription
                add_subscription_ids(updated_subscription)
                self.save
            end
        end
    end

    #Returns list of hashes for changes
    def calculate_stripe_changes
        #Make a copy of the old Stripe products
        previous_products = stripe_products.clone
        current_products = Hash.new

        products = get_stripe_products_for_vehicle(self.vehicle_id)

        if current_products.key?(products[:driver_front].stripe_id)
            current_products[products[:driver_front].stripe_id]['quantity'] += 1
        else
            current_products[products[:driver_front].stripe_id] = { 'quantity' => 1, 'subscription_id' => nil }
        end

        if !products[:passenger_front].nil?
            if current_products.key?(products[:passenger_front].stripe_id)
                current_products[products[:passenger_front].stripe_id]['quantity'] += 1
            else
                current_products[products[:passenger_front].stripe_id] = { 'quantity' => 1, 'subscription_id' => nil }
            end
        end

        if !products[:rear].nil?
            if current_products.key?(products[:rear].stripe_id)
                current_products[products[:rear].stripe_id]['quantity'] += 1
            else
                current_products[products[:rear].stripe_id] = { 'quantity' => 1, 'subscription_id' => nil }
            end
        end

        updated_products = Hash.new
        current_products.each do |key, value|
            if previous_products.key?(key)
                #If items exists in both lists with a different quantity, then it is changed
                if !(previous_products[key]['quantity'] == value['quantity'])
                    updated_products[key] = value
                    updated_products[key]['subscription_id'] = previous_products[key]['subscription_id']
                end

                previous_products.delete(key)
                current_products.delete(key)
            end
        end

        #Items left in previous products are deleted
        #Items left in current products are added
        #Changed items have been marked

        return { new: current_products, updated: updated_products, deleted: previous_products }
    end

    def update_shipping_dates
        shipment = self.shippings.where('scheduled_date > ?', DateTime.now).first
        #Update the next shipping date if there is one
        if !shipment.nil?
            shipment.update(scheduled_date: (Time.at(self.cycle_anchor) + (self.frequency == 'six_months' ? 6.month : 1.year)).to_datetime)
        end
        
    end
end