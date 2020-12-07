class WebhookController < ApplicationController
    protect_from_forgery except: :stripe_webhook

    def stripe_webhook
        webhook_secret = Rails.application.credentials.webhook_secret
        payload = request.body.read
        if !webhook_secret.empty?
            # Retrieve the event by verifying the signature using the raw body and secret if webhook signing is configured.
            sig_header = request.env['HTTP_STRIPE_SIGNATURE']
            event = nil
        
            begin
                event = Stripe::Webhook.construct_event(payload, sig_header, webhook_secret)
                rescue JSON::ParserError => e
                    # Invalid payload
                    head :bad_request
                    return
                rescue Stripe::SignatureVerificationError => e
                    # Invalid signature
                    head :bad_request
                    return
            end
        else
            data = JSON.parse(payload, symbolize_names: true)
            event = Stripe::Event.construct_from(data)
        end

        # Get the type of webhook event sent
        event_type = event['type']
        data = event['data']
        data_object = data['object']
        msg = ''
        
        if event_type == 'invoice.payment_succeeded'
            #data_object is an invoice
        
            customer = User.find_by(stripe_customer_id: data_object.customer)
            if customer.nil?
                head :bad_request
                return
            end

            #Find the associated subscription
            order = OrderOption.find_by(subscription_id: data_object.subscription)
            if order.nil?
                head :bad_request
                return
            end

            #Mark the shipment as paid
            shipment = self.shippings.where('scheduled_date > ?', DateTime.now).first
            shipment.update(paid: true)

            #Reset the cycle anchor
            order.update(cycle_anchor: data_object.period_start)
        end
        
        if event_type == 'invoice.payment_failed'
            #data_object is an invoice

            # If the payment fails or the customer does not have a valid payment method,
            # an invoice.payment_failed event is sent, the subscription becomes past_due.
            # Use this webhook to notify your user that their payment has
            # failed and to retrieve new card details.

            customer = User.find_by(stripe_customer_id: data_object.customer)
            if customer.nil?
                head :bad_request
                return
            end

            #Find the associated subscription
            order = OrderOption.find_by(subscription_id: data_object.subscription)
            if order.nil?
                head :bad_request
                return
            end

            UserMailer.payment_failed(customer, order).deliver_now
        end

        if event_type == 'invoice.upcoming'
            #data_object is an invoice

            #Get the customer that this invoice is associated with
            customer = User.find_by(stripe_customer_id: data_object.customer)
            if customer.nil?
                head :bad_request
                return
            end

            #Find the associated subscription
            order = OrderOption.find_by(subscription_id: data_object.subscription)
            if order.nil?
                head :bad_request
                return
            end

            #Update the total price of the order in case it's wrong
            order.total_price = data_object.total
            order.save

            #Send an email to the customer
            UserMailer.upcoming_subscription(customer, order).deliver_now
        end

        # head :ok

        respond_to do |format|
            msg = { status: 'success' }
            format.json { render :json => msg } 
        end
    end
end
