    let stripe, customer, price, card;
  
    function stripeElements(publishableKey) {
      stripe = Stripe(publishableKey);
  
      if (document.getElementById('card-element')) {
        let elements = stripe.elements();
  
        // Card Element styles
        let style = {
          base: {
            fontSize: '16px',
            color: '#32325d',
            fontFamily:
              '-apple-system, BlinkMacSystemFont, Segoe UI, Roboto, sans-serif',
            fontSmoothing: 'antialiased',
            '::placeholder': {
              color: '#a0aec0',
            },
          },
        };
  
        card = elements.create('card', { style: style });
  
        card.mount('#card-element');
  
        card.on('focus', function () {
          let el = document.getElementById('card-element-errors');
          el.classList.add('focused');
        });
  
        card.on('blur', function () {
          let el = document.getElementById('card-element-errors');
          el.classList.remove('focused');
        });
  
        card.on('change', function (event) {
          displayError(event);
        });
      }
    }

    //If you are sniffing around, don't call this
    //All you will do is create a charge without a user account
    function runStripe() {
      // Create customer
      createCustomer().then((result) => {
        customer = result.customer;
        customerId = customer.id;
        customerName = result.name;

        // If a previous payment was attempted, get the lastest invoice
        const latestInvoicePaymentIntentStatus = localStorage.getItem(
          'latestInvoicePaymentIntentStatus'
        );

        if (latestInvoicePaymentIntentStatus === 'requires_payment_method') {
          const invoiceId = localStorage.getItem('latestInvoiceId');
          const isPaymentRetry = true;
          // create new payment method & retry payment on invoice with new payment method
          createPaymentMethod({
            card,
            customerId,
            customerName,
            isPaymentRetry,
            invoiceId,
          });
        } else {
          // create new payment method & create subscription
          createPaymentMethod({ card, customerId, customerName });
        }
      });
    }
    
    function displayError(event) {
      let displayError = document.getElementById('card-element-errors');
      if (event.error) {
        displayError.textContent = event.error.message;
      } else {
        displayError.textContent = '';
      }
      button = document.getElementById('submit-button');
      button.innerHTML = "Submit Order";
      button.disabled = false;
    }
  
    function createPaymentMethod({ card, customerId, billingName, isPaymentRetry, invoiceId }) {
      // Set up payment method for recurring usage
 
      stripe
        .createPaymentMethod({
          type: 'card',
          card: card,
          billing_details: {
            name: billingName,
          },
        })
        .then((result) => {
          if (result.error) {
            displayError(error);
          } else {
            if (isPaymentRetry) {
              // Update the payment method and retry invoice payment
              retryInvoiceWithNewPaymentMethod({
                customerId: customerId,
                paymentMethodId: result.paymentMethod.id,
                invoiceId: invoiceId
              });
            } else {
              // Create the subscription
              createSubscription({
                customerId: customerId,
                paymentMethodId: result.paymentMethod.id
              });
            }
          }
        });
    }
  
    function createCustomer() {
  
      return fetch('/create-customer', {
        method: 'post',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        }
      })
        .then((response) => {
          return response.json();
        })
        .then((result) => {
          console.log(result);
          return result;
        });
    }
  
    function handleCustomerActionRequired({
      subscription,
      invoice,
      paymentMethodId,
      isRetry,
    }) {
      if (subscription && subscription.status === 'active') {
        // subscription is active, no customer actions required.
        return { subscription, paymentMethodId };
      }
  
      // If it's a first payment attempt, the payment intent is on the subscription latest invoice.
      // If it's a retry, the payment intent will be on the invoice itself.
      let paymentIntent = invoice
        ? invoice.payment_intent
        : subscription.latest_invoice.payment_intent;
  
      if (
        paymentIntent.status === 'requires_action' ||
        (isRetry === true && paymentIntent.status === 'requires_payment_method')
      ) {
        return stripe
          .confirmCardPayment(paymentIntent.client_secret, {
            payment_method: paymentMethodId,
          })
          .then((result) => {
            if (result.error) {
              // start code flow to handle updating the payment details
              // Display error message in your UI.
              // The card was declined (i.e. insufficient funds, card has expired, etc)
              throw result;
            } else {
              if (result.paymentIntent.status === 'succeeded') {
                // There's a risk of the customer closing the window before callback
                // execution. To handle this case, set up a webhook endpoint and
                // listen to invoice.payment_succeeded. This webhook endpoint
                // returns an Invoice.
                return {
                  subscription: subscription,
                  invoice: invoice,
                  paymentMethodId: paymentMethodId,
                };
              }
            }
          });
      } else {
        // No customer action needed
        return { subscription, paymentMethodId };
      }
    }
  
    function handlePaymentMethodRequired({
      subscription,
      paymentMethodId,
    }) {
      if (subscription.status === 'active') {
        // subscription is active, no customer actions required.
        return { subscription, paymentMethodId };
      } else if (
        subscription.latest_invoice.payment_intent.status ===
        'requires_payment_method'
      ) {
        // Using localStorage to store the state of the retry here
        // (feel free to replace with what you prefer)
        // Store the latest invoice ID and status
        localStorage.setItem('latestInvoiceId', subscription.latest_invoice.id);
        localStorage.setItem(
          'latestInvoicePaymentIntentStatus',
          subscription.latest_invoice.payment_intent.status
        );
        throw { error: { message: 'Your card was declined.' } };
      } else {
        return { subscription, paymentMethodId };
      }
    }
  
    function onSubscriptionComplete(result) {
      console.log(result);
      // Payment was successful. Provision access to your service.
      // Remove invoice from localstorage because payment is now complete.
      localStorage.clear();

      fetch('/subscription-complete', {
        method: 'get',
        headers: {
          'Content-type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        }
      });

      //Redirect to thank you page
      window.location='/checkouts/success'
    }
  
    function createSubscription({ customerId, paymentMethodId, priceId }) {
      return (
        fetch('/create-subscription', {
          method: 'post',
          headers: {
            'Content-type': 'application/json',
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
          },
          body: JSON.stringify({
            customerId: customerId,
            paymentMethodId: paymentMethodId
          }),
        })
          .then((response) => {
            return response.json();
          })
          // If the card is declined, display an error to the user.
          .then((result) => {
            if (result.error) {
              // The card had an error when trying to attach it to a customer
              throw result;
            }
            return result;
          })
          // Normalize the result to contain the object returned
          // by Stripe. Add the addional details we need.
          .then((result) => {
            return {
              // Use the Stripe 'object' property on the
              // returned result to understand what object is returned.
              subscription: result,
              paymentMethodId: paymentMethodId
            };
          })
          // Some payment methods require a customer to do additional
          // authentication with their financial institution.
          // Eg: 2FA for cards.
          .then(handleCustomerActionRequired)
          // If attaching this card to a Customer object succeeds,
          // but attempts to charge the customer fail. You will
          // get a requires_payment_method error.
          .then(handlePaymentMethodRequired)
          // No more actions required. Provision your service for the user.
          .then(onSubscriptionComplete)
          .catch((error) => {
            // An error has happened. Display the failure to the user here.
            // We utilize the HTML element we created.
            displayError(error);
          })
      );
    }
  
    function getConfig() {
      return fetch('/setup', {
        method: 'get',
        headers: {
          'Content-Type': 'application/json',
        },
      })
        .then((response) => {
          return response.json();
        })
        .then((response) => {
          // Set up Stripe Elements
          stripeElements(response.publishableKey);
        });
    }
  
    getConfig();