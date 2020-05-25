class CheckoutsController < ApplicationController
before_action :logged_in_user,  only: [:new, :thankyou, :create]
before_action :calculate_total
before_action :set_description

def new
end

def thankyou
end

def create
    customer = StripeTool.create_customer(email: params[:stripeEmail], 
                                          stripe_token: params[:stripeToken])

    charge = StripeTool.create_charge(customer_id: customer.id, 
                                      amount: @amount,
                                      description: @description)

    redirect_to thankyou_path
rescue Stripe::CardError => e
    flash[:error] = e.message
    redirect_to new_charge_path
end

private

def calculate_total
    @amount = 500
end

def set_description
    @description = "Sample Subscription"
end

end