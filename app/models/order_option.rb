class OrderOption < ApplicationRecord
    belongs_to :user
    has_one :shipping_address
    before_save :update_next_delivery
    before_save :calculate_stripe_products

    enum frequency: [ :six_months, :one_year ]
    enum quality: [ :good, :better, :best ]

    private

        def update_next_delivery
            if (self.six_months?)
                self.next_delivery = DateTime.now + 6.months
            else
                self.next_delivery = DateTime.now + 12.months
            end
        end

        #Method to map wiper sizes, quality, and frequency to the correct stripe price ID
        def calculate_stripe_products
            self.vehicle_id.each do |id|
                #Get the associated stripe product for the vehicle and parameters
                vehicle = Vehicle.find(id)
                driverFront = StripeProduct.where(size: vehicle.driver_front, quality: OrderOption.qualities[self.quality] , frequency: OrderOption.frequencies[self.frequency]).first
                passengerFront = StripeProduct.where(size: vehicle.passenger_front, quality: OrderOption.qualities[self.quality], frequency: OrderOption.frequencies[self.frequency]).first
                rear = StripeProduct.where(size: vehicle.rear, quality: OrderOption.qualities[self.quality], frequency: OrderOption.frequencies[self.frequency]).first
                
                #Calculate total price
                self.total_price = driverFront.price + passengerFront.price

                #Add to the lists of stripe products
                self.stripe_product.push(driverFront.stripe_id)
                self.stripe_product.push(passengerFront.stripe_id)

                if(!rear.nil?)
                    self.stripe_product.push(rear.stripe_id)
                    self.total_price += rear.price
                end
            end
        end
end
