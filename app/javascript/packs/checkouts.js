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



$(document).on('ajax:error', '#user-form', event => {
    button = document.getElementById('submit-button');
    button.innerHTML = "Submit Order";
    button.disabled = false;

    const [response, status, xhr] = event.detail;
    clearErrors();
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
});

$(document).on('ajax:success', '#user-form', event => {
    clearErrors();
    runStripe();
});

$("#user_form").submit(function() { 
    button = ("#submit-button");
    button.prop("disabled", true);
    button.html("<i class='fa fa-spinner fa-spin'></i><span class='sr-only'>Processing...</span>")
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
}

document.addEventListener('turbolinks:load', () => {
    addListeners();
});

addListeners();