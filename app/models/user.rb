class User < ApplicationRecord
  include ActiveModel::Dirty

  attr_accessor :remember_token, :activation_token, :reset_token
  has_many :order_options, dependent: :destroy, inverse_of: :user
  before_validation :downcase_email
  before_save :update_billing_method, if: :will_save_change_to_payment_method_id?
  before_create :create_activation_digest
  validates :name,  presence: true, length: { maximum: 50 }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 255 },
                    format: { with: VALID_EMAIL_REGEX },
                    uniqueness: true
  has_secure_password
  validates :password, presence: true, length: { minimum: 6 }, allow_nil: true

  # Returns the hash digest of the given string.
  def User.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                                                  BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end

  # Returns a random token. 
  def User.new_token
    SecureRandom.urlsafe_base64
  end

  # Remembers a user in the database for use in persistent sessions.
  def remember
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(remember_token))
  end

  # Returns true if the given token matches the digest.
  def authenticated?(attribute, token)
    digest = send("#{attribute}_digest")
    return false if digest.nil?
    BCrypt::Password.new(digest).is_password?(token)
  end

  # Forgets a user.
  def forget
    update_attribute(:remember_digest, nil)
  end

  # Activates an account.
  def activate
    update_attribute(:activated,    true)
    update_attribute(:activated_at, DateTime.now)
  end

  # Sends activation email.
  def send_activation_email
    #Create and save a digest
    self.activation_token  = User.new_token
    self.activation_digest = User.digest(activation_token)
    self.save

    UserMailer.account_activation(self).deliver_now
  end

  # Sets the password reset attributes.
  def create_reset_digest
    self.reset_token = User.new_token
    update_attribute(:reset_digest,  User.digest(reset_token))
    update_attribute(:reset_sent_at, Time.zone.now)
  end

  # Sends password reset email.
  def send_password_reset_email
    UserMailer.password_reset(self).deliver_now
  end

  # Returns true if a password reset has expired.
  def password_reset_expired?
    reset_sent_at < 2.hours.ago
  end

  private
    def update_billing_method
      unless payment_method_id_change_to_be_saved[0].nil?
        #Attach new payment method to customer
        puts "Updating billing method"
        begin
          Stripe::PaymentMethod.attach(payment_method_id_change_to_be_saved[1],
            { customer: self.stripe_customer_id })

          #Display an error screen if something goes wrong
          rescue Stripe::CardError => e
            errors.add(:paymentMethodId, "Error attaching payment method")
            raise ActiveRecord::RecordInvalid.new(self)
            #Need to log this
            #halt 200, { 'Content-Type' => 'application/json' }, { 'error': { message: e.error.message } }.to_json
        end

        #Set the new payment method as default
        Stripe::Customer.update(
          self.stripe_customer_id,
          invoice_settings: {
            default_payment_method: payment_method_id_change_to_be_saved[1]
          }
        )

        #Remove the old payment method
        Stripe::PaymentMethod.detach(
          payment_method_id_change_to_be_saved[0]
        )
      end
    end
    
      
    # Converts email to all lower-case.
    def downcase_email
      self.email = email.downcase
    end

    # Creates and assigns the activation token and digest.
    def create_activation_digest
      self.activation_token  = User.new_token
      self.activation_digest = User.digest(activation_token)
    end
  end
