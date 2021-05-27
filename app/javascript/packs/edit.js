import 'smartwizard/dist/js/jquery.smartWizard.min.js'

function updateShippingPreview() {
    result = $("#address1_field").val() + " ";
    result += $("#address2_field").val() + "<br/>";
    result += $("#city_field").val() + " ";
    result += $("#state_field").val() + " ";
    result += $("#postal_field").val();
    $("#shipping_preview").html(result);
}

//Functions to update the preview container
function updateVehiclePreview() {
  var make = $("#make-selector").find(":selected").text();
  var model = $("#model-selector").find(":selected").text();
  var year = $("#vehicle-id").find(":selected").text();

  $("#vehicle-preview").text(`${year} ${make} ${model}`);
}

function updateMake(makeId) {
  $.get( "/get_models_by_make", { id: makeId }, function( data ) {
    $("#model-selector").html("");
    $("#vehicle-id").html("");
    //Include a blank row
    $("#model-selector").append("<option value label=\" \"</option>");
    $.each(data, function(i, value) {
      $("#model-selector").append("<option value='" + value.id + "'>" + value.model + "</option>");
    });
  });
};

function updateModel(modelId) {
  $.get( "/get_years_by_model", { id: modelId }, function(data) {
    $("#vehicle-id").html("");
    //Include a blank row
    $("#vehicle-id").append("<option value label=\" \"</option>");
    $.each( data, function(i, value) {
      $("#vehicle-id").append("<option value='" + value.id + "'>" + value.year + "</option>");
    });
  });
};

function updateWiperTypePreview(wipertypeString) {
  $("#wipertype_preview").text(wipertypeString);
}

function updateFrequencyPreview(frequencyString) {
  $("#frequency_preview").text(frequencyString);
}

function validatePage(stepIndex, stepDirection) {
  if(stepIndex === 1 && stepDirection == "forward") {
    //Verify all vehicles selectors have been filled out
    if($("#vehicle-id").length) {
      if($("#vehicle-id").val() === "" || $("#model-selector").val() === "") {
        $('#smartwizard').smartWizard({
          errorSteps: [1]
        });
        $("#smartwizard").smartWizard("goToStep", 1)
        return;
      }
    }
  }
  else if (stepIndex === 2 && stepDirection == "forward") {
    //Verify a wiper type has been selected
    if ($("input[name='order_option[wipertype]']:checked").val()) {
      $('#smartwizard').smartWizard({
        errorSteps: []
      });
    }
    else {
      $('#smartwizard').smartWizard({
        errorSteps: [2]
      });
      $("#smartwizard").smartWizard("goToStep", 2)
    }
  }
  else if (stepIndex === 3 && stepDirection == "forward") {
    //Verify a frequency has been selected
    if ($("input[name='order_option[frequency]']:checked").val()) {
      $('#smartwizard').smartWizard({
        errorSteps: []
      });
    }
    else {
      $('#smartwizard').smartWizard({
        errorSteps: [3]
      });
      $("#smartwizard").smartWizard("goToStep", 3)
    }
  }
}

function addListeners() {
  //Put a listener on everything
  $('#make-selector').change(function() {
      var makeId = $(this).val();
      updateMake(makeId);
  });

  $('#model-selector').change(function() {
      var modelId = $(this).val();
      updateModel(modelId);
  });
  $("#vehicle-id").change(function() {
    updateVehiclePreview();
  });

  //Wiper type selection listeners
  $("#beam_button").click(function() {
    updateWiperTypePreview("Beam");
  });

  $("#hybrid_button").click(function() {
    updateWiperTypePreview("Hybrid");
  });

  //Frequency selection listeners
  $("#six_months_button").click(function() {
    updateFrequencyPreview("Every 6 Months");
  });

  $("#nine_months_button").click(function() {
    updateFrequencyPreview("Every 9 Months");
  });

  $("#year_button").click(function() {
    updateFrequencyPreview("Every 12 Months");
  });

  $("#address1_field").focusout(function() {
      updateShippingPreview();
  });

  $("#address2_field").focusout(function() {
      updateShippingPreview();
  });

  $("#city_field").focusout(function() {
      updateShippingPreview();
  });

  $("#state_field").focusout(function() {
      updateShippingPreview();
  });

  $("#postal_field").focusout(function() {
      updateShippingPreview();
  });

  $("#smartwizard").on("stepContent", function(e, anchorObject, stepIndex, stepDirection) {
    validatePage(stepIndex, stepDirection);
  });

  $('#smartwizard').smartWizard({
    theme: 'arrows',
    justified: true,
    enableURLhash: false,
    keyNavigation: false,
    autoAdjustHeight: false,
    transition: {
      animation: 'none',
      speed: '400',
      easing:''
    },
    toolbarSettings: {
      toolbarPosition: 'bottom',
      toolbarButtonPosition: 'left'
    },
    anchorSettings: {
      removeDoneStepOnNavigateBack: false,
      anchorClickable: true,
      enableAnchorOnDoneStep: true
    }
  });
}

document.addEventListener('turbolinks:load', () => {
  addListeners();
});

addListeners();