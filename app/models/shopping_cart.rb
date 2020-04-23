class ShoppingCart < ApplicationRecord
    belongs_to :user, optional: true
    has_many :order_options, dependent: :destroy
end
