class ShippingAddress < ApplicationRecord
    belongs_to :user
    belongs_to :order_option, optional: true
    validates :address1, :city, :state, :postal, presence: true
end
