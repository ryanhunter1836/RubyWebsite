document.addEventListener("turbolinks:load", function() {
    // Create a Checkout Session with the selected plan ID
    var createCheckoutSession = function(priceId) {
        return fetch("/create-checkout-session", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            'X-CSRF-Token': $('meta[name=csrf-token]').attr('content')
          },
          body: JSON.stringify({
            priceId: priceId
          })
        }).then(function(result) {
          return result.json();
        });
      };
      
      // Handle any errors returned from Checkout
      var handleResult = function(result) {
        if (result.error) {
          var displayError = document.getElementById("error-message");
          displayError.textContent = result.error.message;
        }
      };
      
      /* Get your Stripe publishable key to initialize Stripe.js */
      fetch("/setup")
        .then(function(result) {
          return result.json();
        })
        .then(function(json) {
          var publishableKey = json.publishableKey;
          var basicPriceId = json.basicPrice;
          var proPriceId = json.proPrice;
      
          var stripe = Stripe(publishableKey);
          // Setup event handler to create a Checkout Session when button is clicked
          document
            .getElementById("submit-button")
            .addEventListener("click", function(evt) {
              createCheckoutSession(basicPriceId).then(function(data) {
                // Call Stripe.js method to redirect to the new Checkout page
                stripe
                  .redirectToCheckout({
                    sessionId: data.sessionId
                  })
                  .then(handleResult);
              });
            });
        });
    });