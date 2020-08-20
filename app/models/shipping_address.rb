class ShippingAddress
    include ActiveModel::Model

    attr_accessor :address1, :address2, :city, :state, :postal

    validates :address1, presence: true
    validates :city, presence: true
    validates :state, presence: true
    validates :postal, presence: true
end
