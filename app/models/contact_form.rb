class ContactForm
    include ActiveModel::Model
    include ActiveModel::Validations::Callbacks

    VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
    validates :email, presence: true, length: { maximum: 255 },
                    format: { with: VALID_EMAIL_REGEX }
    validates :name, presence: true
    validates :message, presence: true

    attr_accessor :name, :email, :message
end