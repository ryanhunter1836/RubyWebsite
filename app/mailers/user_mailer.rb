class UserMailer < ApplicationMailer
  default from: 'no-reply@wiperstoyou.com'

  def account_activation(user)
    @user = user
    mail to: user.email, subject: "WipersToYou.com Account Activation"
  end

  def password_reset(user)
    @user = user
    mail to: user.email, subject: "Password reset"
  end
end
