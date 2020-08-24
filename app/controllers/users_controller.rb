class UsersController < ApplicationController
  before_action :logged_in_user, only: [:show, :new, :edit, :update, :destroy]
  before_action :correct_user,   only: [:show, :new, :edit, :update, :destroy]
  before_action :admin_user,     only: :destroy

  def show
    @user = User.find(params[:id])
    @order_options = @user.order_options
    shipping = Stripe::Customer.retrieve(current_user.stripeCustomerId).shipping
    @shipping_address = ShippingAddress.new(
        address1: shipping.address.line1,
        address2: shipping.address.line2,
        city: shipping.address.city,
        state: shipping.address.state,
        postal: shipping.address.postal_code
    )
  end

  def edit
    @user = User.find(params[:id])
    @paymentMethod = getCardString(Stripe::PaymentMethod.retrieve(@user.paymentMethodId))
  end

  def update
    user = User.find(params[:id])
    if user.update(user_params)
      flash[:success] = "Profile updated!"
      redirect_to @user
    else
      render 'edit'
    end
  end

  def destroy
    User.find(params[:id]).destroy
    flash[:success] = "User deleted"
    redirect_to users_url
  end

  private

    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation, :paymentMethodId)
    end

    # Confirms an admin user.
    def admin_user
      redirect_to(root_url) unless current_user.admin?
    end

    # Confirms the correct user.
  def correct_user
    @user = User.find(params[:id])
    redirect_to(root_url) unless current_user?(@user)
  end

  def getCardString(paymentMethod)
    paymentMethod.card.brand.capitalize() + " ••••" + paymentMethod.card.last4
  end
end
