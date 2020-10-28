class Shipping < ApplicationRecord
    belongs_to :order_option
    validates :order_option_id, presence: true
end
