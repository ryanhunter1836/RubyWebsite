class UserMailer < ApplicationMailer
  add_template_helper(VehicleHelper)

  default from: 'no-reply@wiperstoyou.com'

  def account_activation(user)
    @user = user
    @orders = @user.order_options.all

    @order_numbers = []
    @orders.each do |order|
      @order_numbers.append(order.shippings.all.order("scheduled_date DESC").first.order_number)
    end

    mail to: user.email, subject: "Account Activation"
  end

  def password_reset(user)
    @user = user
    mail to: user.email, subject: "Password Reset"
  end

  #Summary of all subscriptions after one has been changed
  def subscription_change(user)
    @orders = user.order_options.all

    @order_numbers = []
    @orders.each do |order|
      @order_numbers.append(order.shippings.all.order("scheduled_date DESC").first.order_number)
    end

    mail to: user.email, subject: "Subscription Modification"
  end

  def subscription_addition(user)
    @orders = user.order_options.all

    @order_numbers = []
    @orders.each do |order|
      @order_numbers.append(order.shippings.all.order("scheduled_date DESC").first.order_number)
    end

    mail to: user.email, subject: "Subscription Confirmation"
  end 

  def subscription_cancel(user, order)
    @order = order
    mail to: user.email, subject: "Subscription Cancellation"
  end

  def refund_request(user, order_option_id, return_object)
    @user = user
    order = OrderOption.find(order_option_id)

    @products = []
    order.stripe_products.each do |stripe_product_id, parameters|
      quantity = parameters["quantity"]

      stripe_product = StripeProduct.find_by(stripe_id: stripe_product_id)
      size = stripe_product.size

      wipertype = stripe_product.wipertype
      if wipertype == 0
        wipertype = "Beam"
      else
        wipertype = "Hybrid"
      end

      @products.append([size, wipertype, quantity])
    end

    @order_number = return_object.order_number
    @reason = return_object.reason
    @payment_intent_id = Shipping.find_by(order_number: return_object.order_number).payment_intent_id

    mail from: user.email, to: "returns@wiperstoyou.com", subject: "Return Request"
  end

  def upcoming_subscription(user, order)
    @order = order
    mail to: user.email, subject: "Upcoming Subscription"
  end

  def payment_failed(user, order)
    @order = order
    mail to: user.email, subject: "Payment Error"
  end
end
