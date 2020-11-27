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
    var customer = result.customer;
    var customerId = customer.id;
    var customerName = result.name;

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
    var displayError = document.getElementById('card-element-errors');
    if (event.error) {
    displayError.textContent = event.error.message;
    } 
    else {
    displayError.textContent = '';
    }
    var button = document.getElementById('submit-button');
    button.innerHTML = "Submit Order";
    button.disabled = false;
}

function createPaymentMethod({ card, customerId, billingName, userId, isPaymentRetry, invoiceId }) {
    var address1 = "";
    var address2 = "";
    var city = "";
    var state = "";
    var postal = "";

    if ($("#same_as_shipping").is(':checked')) {
        address1 = document.getElementById("address1_field").value;
        address2 = document.getElementById("address2_field").value;
        city = document.getElementById("city_field").value;
        state = document.getElementById("state_field").value;
        postal = document.getElementById("postal_field").value;
    }
    else {
        address1 = document.getElementById("billing_address1_field").value;
        address2 = document.getElementById("billing_address2_field").value;
        city = document.getElementById("billing_city_field").value;
        state = document.getElementById("billing_state_field").value;
        postal = document.getElementById("billing_postal_field").value;
    }

    // Set up payment method for recurring usage
    stripe.createPaymentMethod({
    type: 'card',
    card: card,
    billing_details: {
        name: billingName,
        email: document.getElementById('email_field').value,
        address: {
            city: city,
            country: "US",
            line1: address1,
            line2: address2,
            postal_code: postal,
            state: state
        }
    },
    }).then((result) => {
    if (result.error) {
        displayError(result);
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
        postal: document.getElementById('postal_field').value,
        phone: document.getElementById('phone_field').value
    })
    }).then((response) => {
        return response.json();
    }).then((result) => {
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
    var paymentIntent = invoice ? invoice.payment_intent : subscription.latest_invoice.payment_intent;

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

    var url = "/subscription-complete/" + userId
    fetch(url, {
    method: 'get',
    headers: {
        'Content-type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
    }
    }).then((response) => {
    url = "/checkouts/success/" + userId;
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
    var messageElementName = elementName + "_error";
    var fieldElementName = elementName + "_field";
    var message = name + " " + message;
    var messageElement = document.getElementById(messageElementName);
    messageElement.innerHTML = message;
    messageElement.classList.add("invalid-feedback");
    document.getElementById(fieldElementName).classList.add("is-invalid");
}

function clearErrors() {
    for(var i = 0; i < userElements.length; i++) {
        var messageElementName = userElements[i] + "_error";
        var fieldElementName = userElements[i] + "_field";
        var messageElement = document.getElementById(messageElementName);
        messageElement.innerHTML = "";
        messageElement.classList.remove("invalid-feedback");
        document.getElementById(fieldElementName).classList.remove("is-invalid");
    }
    for(var i = 0; i < shippingElements.length; i++) {
        var messageElementName = shippingElements[i] + "_error";
        var fieldElementName = shippingElements[i] + "_field";
        var messageElement = document.getElementById(messageElementName);
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
        for(var i = 0; i < userElements.length; i++) {
        if(userElements[i] in response['user']) {
            inlineError(userElementNames[i], userElements[i], response['user'][userElements[i]][0]);
        }
        }

        //Loop through the shipping elements
        for(var i = 0; i < shippingElements.length; i++) {
        if(shippingElements[i] in response['address']) {       
            inlineError(shippingElementNames[i], shippingElements[i], response['address'][shippingElements[i]][0]);
        }
        }

        //Re-enable the submit button
        var button = document.getElementById('submit-button');
        button.innerHTML = "Submit Order";
        button.disabled = false;
    }
});

function addListeners() {
    $("#same_as_shipping").change(function(){
        if ($(this).is(':checked')) {
            $("#billing_address_fields").hide();
        }
        else {
            $("#billing_address_fields").show();
        }
    });

    $("#user-form").submit(function(e) {
        //Check to make sure the user has agreed to the privacy policy
        if($("#privacy_check").is(":checked")) {
            var button = $("#submit-button");
            button.prop("disabled", true);
            button.html("<i class='fa fa-spinner fa-spin'></i><span class='sr-only'>Processing...</span>")
        }
        else {
            window.alert("Please accept the privacy policy before continuing");
            e.preventDefault();
        }
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