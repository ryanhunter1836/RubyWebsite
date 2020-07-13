class UsersController < ApplicationController
  before_action :logged_in_user, only: [:show, :new, :edit, :update, :destroy]
  before_action :correct_user,   only: [:show, :new, :edit, :update, :destroy]
  before_action :admin_user,     only: :destroy

  def show
    @user = User.find(params[:id])
    @order_options = @user.order_options
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      @user.send_activation_email
      flash[:info] = "Please check your email to activate your account."
      redirect_to root_url
    else
      render 'new'
    end
  end

  def edit
    @user = User.find(params[:id])
    @paymentMethod = getCardString(Stripe::PaymentMethod.retrieve(@user.paymentMethodId))
  end

  def update
    @user = User.find(params[:id])
    if @user.update(user_params)
      flash[:success] = "Profile updated"
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

  def retrieve_customer_payment_method
    data = JSON.parse request.body.read
  
    payment_method = Stripe::PaymentMethod.retrieve(data['paymentMethodId'])
  
    payment_method.to_json
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
