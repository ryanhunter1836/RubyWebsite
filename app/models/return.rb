class Return
    include ActiveModel::Model
    include ActiveModel::Validations::Callbacks

    validates :reason, presence: true
    validates :order_number, presence: true
    
    attr_accessor :reason, :order_number
end