const userElements = [
"name", 
"email", 
"password", 
"password_confirmation"
];

const shippingElements = [
"address1", 
"city", 
"state", 
"postal"
];

const userElementNames = [
    "Name",
    "Email",
    "Password",
    "Password confirmation"
]

const shippingElementNames = [
    "Address",
    "City",
    "State",
    "Zip code"
]

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

function runStripe(userId) {
  // Create customer
  createCustomer(userId).then((result) => {
    customer = result.customer;
    customerId = customer.id;
    customerName = result.name;

    // If a previous payment was attempted, get the lastest invoice
    const latestInvoicePaymentIntentStatus = localStorage.getItem('latestInvoicePaymentIntentStatus');

    if (latestInvoicePaymentIntentStatus === 'requires_payment_method') {
      const invoiceId = localStorage.getItem('latestInvoiceId');
      const isPaymentRetry = true;
      // create new payment method & retry payment on invoice with new payment method
      createPaymentMethod({
        card,
        customerId,
        customerName,
        userId,
        isPaymentRetry,
        invoiceId,
      });
    } 
    else {
      // create new payment method & create subscription
      createPaymentMethod({ card, customerId, customerName, userId });
    }
  });
}

function displayError(event) {
  let displayError = document.getElementById('card-element-errors');
  if (event.error) {
    displayError.textContent = event.error.message;
  } 
  else {
    displayError.textContent = '';
  }
  button = document.getElementById('submit-button');
  button.innerHTML = "Submit Order";
  button.disabled = false;
}

function createPaymentMethod({ card, customerId, billingName, userId, isPaymentRetry, invoiceId }) {
  // Set up payment method for recurring usage
  stripe.createPaymentMethod({
    type: 'card',
    card: card,
    billing_details: {
      name: billingName,
    },
  }).then((result) => {
    if (result.error) {
      displayError(error);
    } 
    else {
      if (isPaymentRetry) {
        // Update the payment method and retry invoice payment
        retryInvoiceWithNewPaymentMethod({
          customerId: customerId,
          paymentMethodId: result.paymentMethod.id,
          invoiceId: invoiceId
        });
      }
      else {
        // Create the subscription
        createSubscription({
          customerId: customerId,
          paymentMethodId: result.paymentMethod.id,
          userId: userId
        });
      }
    }
  });
}

function createCustomer(userId) {
  return fetch('/create-customer', {
    method: 'post',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
    },
    body: JSON.stringify({
      user_id: userId,
      address1: document.getElementById('address1_field').value,
      address2: document.getElementById('address2_field').value,
      city: document.getElementById('city_field').value,
      state: document.getElementById('state_field').value,
      postal: document.getElementById('postal_field').value
    })
  }).then((response) => {
      return response.json();
    }).then((result) => {
      console.log(result);
      return result;
    });
}

function handleCustomerActionRequired({subscription, invoice, paymentMethodId, isRetry}) {
  if (subscription && subscription.status === 'active') {
    // subscription is active, no customer actions required.
    return { subscription, paymentMethodId };
  }

  // If it's a first payment attempt, the payment intent is on the subscription latest invoice.
  // If it's a retry, the payment intent will be on the invoice itself.
  let paymentIntent = invoice ? invoice.payment_intent : subscription.latest_invoice.payment_intent;

  if (paymentIntent.status === 'requires_action' || (isRetry === true && paymentIntent.status === 'requires_payment_method')) {
    return stripe.confirmCardPayment(paymentIntent.client_secret, { payment_method: paymentMethodId }).then((result) => {
      if (result.error) {
        // start code flow to handle updating the payment details
        // Display error message in your UI.
        // The card was declined (i.e. insufficient funds, card has expired, etc)
        throw result;
      } 
      else {
        if (result.paymentIntent.status === 'succeeded') {
          // There's a risk of the customer closing the window before callback
          // execution. To handle this case, set up a webhook endpoint and
          // listen to invoice.payment_succeeded. This webhook endpoint
          // returns an Invoice.
          return { subscription: subscription, invoice: invoice, paymentMethodId: paymentMethodId };
        }
      }
    });
  } 
  else {
    // No customer action needed
    return { subscription, paymentMethodId };
  }
}

function handlePaymentMethodRequired({ subscription, paymentMethodId }) {
  if (subscription.status === 'active') {
    // subscription is active, no customer actions required.
    return { subscription, paymentMethodId };
  } 
  else if (subscription.latest_invoice.payment_intent.status === 'requires_payment_method') {
    // Using localStorage to store the state of the retry here
    // (feel free to replace with what you prefer)
    // Store the latest invoice ID and status
    localStorage.setItem('latestInvoiceId', subscription.latest_invoice.id);
    localStorage.setItem('latestInvoicePaymentIntentStatus', subscription.latest_invoice.payment_intent.status);
    throw { error: { message: 'Your card was declined.' } };
  } 
  else {
    return { subscription, paymentMethodId };
  }
}

function onSubscriptionComplete(userId) {
  // Payment was successful. Provision access to your service.
  // Remove invoice from localstorage because payment is now complete.
  localStorage.clear();

  url = "/subscription-complete/" + userId
  fetch(url, {
    method: 'get',
    headers: {
      'Content-type': 'application/json',
      'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
    }
  }).then((response) => {
    url = "/checkouts/success/" + userId;
    console.log(url);
    window.location = url;
  })
}

function createSubscription({ customerId, paymentMethodId, userId }) {
  return (fetch('/create-subscription', {
      method: 'post',
      headers: {
        'Content-type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({
        customerId: customerId,
        paymentMethodId: paymentMethodId,
        user_id: userId
      }),
    }).then((response) => {
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
      .then(onSubscriptionComplete(userId))
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
  }).then((response) => {
      return response.json();
    }).then((response) => {
      // Set up Stripe Elements
      stripeElements(response.publishableKey);
    });
}

function inlineError(name, elementName, message) {
    messageElementName = elementName + "_error";
    fieldElementName = elementName + "_field";
    message = name + " " + message;
    messageElement = document.getElementById(messageElementName);
    messageElement.innerHTML = message;
    messageElement.classList.add("invalid-feedback");
    document.getElementById(fieldElementName).classList.add("is-invalid");
}

function clearErrors() {
    for(i = 0; i < userElements.length; i++) {
        messageElementName = userElements[i] + "_error";
        fieldElementName = userElements[i] + "_field";
        messageElement = document.getElementById(messageElementName);
        messageElement.innerHTML = "";
        messageElement.classList.remove("invalid-feedback");
        document.getElementById(fieldElementName).classList.remove("is-invalid");
    }
    for(i = 0; i < shippingElements.length; i++) {
        messageElementName = shippingElements[i] + "_error";
        fieldElementName = shippingElements[i] + "_field";
        messageElement = document.getElementById(messageElementName);
        messageElement.innerHTML = "";
        messageElement.classList.remove("invalid-feedback");
        document.getElementById(fieldElementName).classList.remove("is-invalid");
    }
}

$(document).on('ajax:success', '#user-form', event => {
    const [response, status, xhr] = event.detail;
    clearErrors();

    //If user account creation was successful, start processing the payment
    if(response['success'] == true) {
      runStripe(response['user_id']);
    }
    //Otherwise, display the errors on the form
    else {
      //Loop through the user elements
      for(i = 0; i < userElements.length; i++) {
        if(userElements[i] in response['user']) {
            inlineError(userElementNames[i], userElements[i], response['user'][userElements[i]][0]);
        }
      }

      //Loop through the shipping elements
      for(i = 0; i < shippingElements.length; i++) {
        if(shippingElements[i] in response['address']) {       
            inlineError(shippingElementNames[i], shippingElements[i], response['address'][shippingElements[i]][0]);
        }
      }

      //Re-enable the submit button
      button = document.getElementById('submit-button');
      button.innerHTML = "Submit Order";
      button.disabled = false;
    }
});

//Functions to update the preview container
function updateVehiclePreview(index) {
  make = $("#make-selector-" + index + " option:selected").text();
  model = $("#model-selector-" + index + " option:selected").text();
  year = $("#vehicle-id-" + index + " option:selected").text();

  $("#vehicle_preview_" + index).text(year + " " + make + " " + model);
}

function updateQualityPreview(qualityString) {
  $("#quality_preview").text(qualityString);
}

function updateFrequencyPreview(frequencyString) {
  $("#frequency_preview").text(frequencyString);
}

function updateMake(makeId, index) {
    $.get( "/get_models_by_make", { id: makeId }, function( data ) {
      $("#model-selector-" + index).html("");
      $("#vehicle-id-" + index).html("");
      //Include a blank row
      $("#model-selector-" + index).append("<option value label=\" \"</option>");
      $.each(data, function(i, value) {
        $("#model-selector-" + index).append("<option value='" + value.id + "'>" + value.model + "</option>");
      });
    });
  };

function updateModel(modelId, index) {
  $.get( "/get_years_by_model", { id: modelId }, function(data) {
    $("#vehicle-id-" + index).html("");
    //Include a blank row
    $("#vehicle-id-" + index).append("<option value label=\" \"</option>");
    $.each( data, function(i, value) {
      $("#vehicle-id-" + index).append("<option value='" + value.id + "'>" + value.year + "</option>");
    });
  });
};

function addListeners() {
  let currentIndex = 2;
  //Add a new listener each time the button is clicked
  $("#add_vehicle_button").click(function () {
      if(currentIndex == 2) {
          $("#make-selector-2").change(function() {
              var makeId = $(this).val();
              updateMake(makeId, 2);
          });
  
          $("#model-selector-2").change(function() {
              var modelId = $(this).val();
              updateModel(modelId, 2);
          });
          $("#vehicle-id-2").change(function() {
            updateVehiclePreview(2);
          });
      }
      else {
          $("#make-selector-3").change(function() {
              var makeId = $(this).val();
              updateMake(makeId, 3);
          });
  
          $("#model-selector-3").change(function() {
              var modelId = $(this).val();
              updateModel(modelId, 3);
          });
          $("#vehicle-id-3").change(function() {
            updateVehiclePreview(3);
          });
      }

      //Add another vehicle preview entry
      let htmlToInsert = "<div id=\"vehicle_preview_" + currentIndex + "\" class=\"vehicle-preview col-12\"></div>";
      document.getElementById("vehicle_preview_container").insertAdjacentHTML('beforeend', htmlToInsert);

      currentIndex++;
  });

  $("#remove_vehicle_button").click(function() {
      if(currentIndex == 4) {
          $("#make-selector-2").off('change');
          $("#model-selector-2").off('change');
      }
      else if(currentIndex == 3) {
          $("#make-selector-3").off('change');
          $("#model-selector-3").off('change');
      }

      //Remove an entry in the vehicle preview container
      elementList = $(".vehicle-preview");
      element = elementList[elementList.length - 1];
      element.parentNode.removeChild(element);

      currentIndex--;
  });

  $('#make-selector-1').change(function() {
      var makeId = $(this).val();
      updateMake(makeId, 1);
  });

  $('#model-selector-1').change(function() {
      var modelId = $(this).val();
      updateModel(modelId, 1);
  });
  $("#vehicle-id-1").change(function() {
    updateVehiclePreview(1);
  });

  //Quality selection listeners
  $("#good_button").click(function() {
    updateQualityPreview("Good");
  });

  $("#better_button").click(function() {
    updateQualityPreview("Better");
  });

  $("#best_button").click(function() {
    updateQualityPreview("Best");
  });

  //Frequency selection listeners
  $("#months_button").click(function() {
    updateFrequencyPreview("Every 6 Months");
  });

  $("#year_button").click(function() {
    updateFrequencyPreview("Every 12 Months");
  });

  $("#user-form").submit(function() { 
    button = $("#submit-button");
    button.prop("disabled", true);
    button.html("<i class='fa fa-spinner fa-spin'></i><span class='sr-only'>Processing...</span>")
  });
}

document.addEventListener('turbolinks:load', () => {
  //The JS is loaded before the elements are actually rendered on the page,
  // so add the listeners after the document is loaded
    addListeners();
});

document.addEventListener('turbolinks:before-render', () => {
  Turbolinks.clearCache();
});

addListeners();
getConfig();