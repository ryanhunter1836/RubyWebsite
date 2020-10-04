class ShoppingCart < ApplicationRecord
    has_many :order_options
end
