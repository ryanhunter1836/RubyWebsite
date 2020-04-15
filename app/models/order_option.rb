class OrderOption < ApplicationRecord
    belongs_to :user
    validates :user_id, presence: true
    has_one :vehicle
    
    enum frequency: [ :three_months, :six_months ]
    enum quality: [ :good, :better, :best ]
end
