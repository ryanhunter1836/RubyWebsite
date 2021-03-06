class ReturnsController < ApplicationController
    before_action :logged_in_user, only: [:new, :create]

    REASONS = [
        ["Wipers are the wrong size", 0],
        ["Wipers don't fit my vehicle", 1],
        ["Wipers are damaged", 2],
        ["Don't need the wipers", 3]
    ]

    def new
        @return = Return.new
        @reasons = REASONS
    end

    def create
        @reasons = REASONS

        refund = Return.new(refund_params)
        
        if refund.valid?
            shipping = Shipping.find_by(order_number: refund.order_number)

            if !shipping.nil?
                if shipping.refund_submitted?
                    flash[:danger] = "Refund has already been requested for this order"
                    redirect_to new_return_path
                else
                    range = (DateTime.now - 35.days)..DateTime.now
                    test = shipping.shipped_at
                    #Verify it is within the 35 day return policy
                    if range.cover?(shipping.shipped_at)       
                        shipping.refund_submitted = true
                        shipping.save

                        UserMailer.refund_request(current_user, shipping.order_option_id, refund).deliver_now
            
                        flash[:success] = "Refund request submitted.  Please check your email for a confirmation"
                        redirect_to user_path(current_user.id)
                    else
                        flash[:warning] = "We're sorry, but refund requests must be submitted within 35 days of payment"
                        redirect_to new_return_path
                    end
                end                
            else
                flash[:danger] = "We couldn't find your order.  Please try again or contact support"
                redirect_to new_return_path
            end
        else
            flash[:warning] = "Please fill out all the fields before continuing"
            redirect_to new_return_path
        end
    end

    private 
    
    def refund_params
        params.require(:return).permit(:reason, :order_number)
    end
end
