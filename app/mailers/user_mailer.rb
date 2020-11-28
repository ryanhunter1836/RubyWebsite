class UserMailer < ApplicationMailer
  add_template_helper(VehicleHelper)

  default from: 'no-reply@wiperstoyou.com'

  def account_activation(user)
    @user = user
    mail to: user.email, subject: "Account Activation"
  end

  def password_reset(user)
    @user = user
    mail to: user.email, subject: "Password Reset"
  end

  #Summary of all subscriptions after one has been changed
  def subscription_change(user)
    @orders = user.order_options.all
    mail to: user.email, subject: "Subscription Modification"
  end

  def subscription_cancel(user, vehicle_id)
    @vehicle_id = vehicle_id
    mail to: user.email, subject: "Subscription Cancellation"
  end

  def upcoming_subscription(user, order)
  end
end
