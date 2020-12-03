class UsersController < ApplicationController
  require 'date'

  before_action :logged_in_user, only: [:show, :edit, :update]
  before_action :correct_user,   only: [:show, :edit, :update]
  before_action :admin_user,     only: [:index, :destroy, :update_admin]

  def index
    start = Date.today.to_s
    if(!params[:start].nil?)
      start = params[:start]
    end

    finish = (Date.today + 30).to_s
    if(!params[:finish].nil?)
      finish = params[:finish]
    end

    @start_date = start
    @end_date = finish

    result_set = User.find_by_sql("SELECT order_options.quality, order_options.vehicle_id, users.name, users.stripe_customer_id, shippings.id, shippings.scheduled_date, shippings.shipped
       FROM order_options, users, shippings WHERE order_options.user_id = users.id AND shippings.order_option_id = order_options.id
       AND shippings.scheduled_date BETWEEN '#{start}' AND '#{finish}';")

    @orders = []

    #Retrieve the address from Stripe
    result_set.each do |order|
      info = Hash.new

      info[:id] = order.id
      info[:quality] = order.quality
      info[:vehicle_id] = order.vehicle_id
      info[:ship_date] = Time.at(order.scheduled_date).to_datetime.in_time_zone("Central Time (US & Canada)").strftime("%m/%d/%Y")
      info[:name] = order.name
      info[:shipped] = order.shipped
      sizes = []
      vehicle_info = Vehicle.find(order.vehicle_id)
      sizes.append(vehicle_info.driver_front)
      if !vehicle_info.passenger_front.nil?
        sizes.append(vehicle_info.passenger_front)
      end
      if !vehicle_info.rear.nil?
        sizes.append(vehicle_info.rear)
      end

      info[:sizes] = sizes

      shipping = Stripe::Customer.retrieve(order.stripe_customer_id).shipping
      info[:shipping] = ShippingAddress.new(
        address1: shipping.address.line1,
        address2: shipping.address.line2,
        city: shipping.address.city,
        state: shipping.address.state,
        postal: shipping.address.postal_code
      )

      @orders.append(info)
    end
  end

  def show
    @user = User.find(params[:id])

    if @user.admin? 
      redirect_to users_path
      return
    end

    @order_options = @user.order_options
    shipping = Stripe::Customer.retrieve(current_user.stripe_customer_id).shipping
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
    @paymentMethod = getCardString(Stripe::PaymentMethod.retrieve(@user.payment_method_id))
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
      params.require(:user).permit(:name, :email, :password, :password_confirmation, :payment_method_id)
    end

    # Confirms an admin user.
    def admin_user
      if current_user.nil?
        redirect_to(root_url)
        return 
      end
      
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

flash[:danger] = "Please activate your account to continue"
