class OrderOption < ApplicationRecord
    belongs-to :users
    has-one :vehicle

    enum frequency: [ :three_months, :six_months ]
    enum quality: [ :good, :better, :best ]
end
