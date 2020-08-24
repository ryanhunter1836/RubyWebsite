let stripe, card;

const capitalize = (s) => {
  if (typeof s !== 'string') {
    return '';
  }
  return s.charAt(0).toUpperCase() + s.slice(1);
}

function stripeElements(publishableKey) {
    stripe = Stripe(publishableKey);
  
    if(document.getElementById('card-element')) {
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
  
      card.on('change', function (event) {
        displayError(event);
      });
    }
  
    document.getElementById("save_button").addEventListener('click', function (evt) {
    evt.preventDefault();
    let customerName = '<%= @user.name %>';

    createPaymentMethod({
      card,
      customerName
    });
  });
}

function createPaymentMethod({ card, billingName }) {
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
      }
      //Update the hidden field with the new payment method id
      else {
        document.getElementById("user_paymentMethodId").value = result.paymentMethod.id;
        document.getElementById("ccLast4").innerHTML = (capitalize(result.paymentMethod.card.brand) + " ••••" + result.paymentMethod.card.last4)
        //Close the modal
        document.getElementById("close_button").click();
      }
      
    });
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