class OrderOption < ApplicationRecord
    belongs_to :shopping_cart
    validates :user_id, presence: true
    has_one :vehicle
    before_save :update_next_delivery

    enum frequency: [ :three_months, :six_months ]
    enum quality: [ :good, :better, :best ]

    private

        def update_next_delivery
        if (self.three_months?)
                self.next_delivery = DateTime.now + 3.months
            else
                self.next_delivery = DateTime.now + 6.months
            end
        end
end
