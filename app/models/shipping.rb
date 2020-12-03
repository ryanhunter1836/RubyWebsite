class Shipping < ApplicationRecord
    require 'securerandom'

    belongs_to :order_option
    validates :order_option_id, presence: true
    after_save :create_next_shipment, if: :saved_change_to_shipped?
    before_save :generate_order_number

    private

    def create_next_shipment
        puts "Creating new shipment"
        if self.shipped?
            #Find the parent order options
            parent_order = OrderOption.find(self.order_option_id)
            if !parent_order.nil?
                frequency = parent_order.frequency

                #Create another shipment that is the appropriate time period away
                if frequency == 'six_months'
                    parent_order.shippings.create(scheduled_date: self.scheduled_date + 6.months)
                else
                    parent_order.shippings.create(scheduled_date: self.scheduled_date + 12.months)
                end
            end
        end
    end

    def generate_order_number
        if self.order_number.nil?
            self.order_number = SecureRandom.alphanumeric(10)
        end
    end
end
