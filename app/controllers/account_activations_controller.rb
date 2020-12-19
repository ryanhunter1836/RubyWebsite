class AccountActivationsController < ApplicationController

  def edit
    user = User.find_by(email: params[:email])
    if user && !user.activated? && user.authenticated?(:activation, params[:id])
      user.activate
      log_in user
      flash[:success] = "Account activated!"
      redirect_to user
    else
      flash[:danger] = "Invalid activation link"
      redirect_to root_url
    end
  end

  def new
  end

  def create
    @user = User.find_by(email: params[:account_activation][:email].downcase)
    if @user
      if @user.activated?
        flash[:info] = "Account already activated"
      else
        @user.send_activation_email
        flash[:info] = "Account activation email sent"
        redirect_to root_url
      end
    else
      flash.now[:danger] = "Email address not found"
      render 'new'
    end
  end
end
