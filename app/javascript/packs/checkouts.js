import 'smartwizard/dist/js/jquery.smartWizard.min.js'

let validateInput = true;

function updateMake(makeId) {
  $.get( "/get_models_by_make", { id: makeId }, function(data) {
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

function validatePage(stepIndex, stepDirection) {
  if(validateInput == true) {
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
}

function removeVehicle(vehicleId) {
  $.ajax({
    url: `/checkouts/${vehicleId}`,
    beforeSend: function(xhr) { xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content')) },
    type: 'DELETE',
    success: function(result) {
      if(result.success == true) {
        //Display a success message
        $(`#${vehicleId}`).hide();
      }
      else {
        window.alert("Oops, something went wrong");
      }
    }
  });
}

function addListeners() {
  validateInput = true;
  let vehicleCount = parseInt($("#num_vehicles").val())

  $('#make-selector').change(function() {
      var makeId = $(this).val();
      updateMake(makeId);
  });

  $('#model-selector').change(function() {
      var modelId = $(this).val();
      updateModel(modelId);
  });
  
  $("#vehicle-id").change(function() {
    var make = $("#make-selector").find(":selected").text();
    var model = $("#model-selector").find(":selected").text();
    var year = $("#vehicle-id").find(":selected").text();

    $("#vehicle-preview").text(`${year} ${make} ${model}`);
  });

  $("#six_months-button").click(function() {
    $("#frequency-preview").text("Every 6 Months");
  });

  $("#nine_months-button").click(function() {
    $("#frequency-preview").text("Every 9 Months");
  });

  $("#year-button").click(function() {
    $("#frequency-preview").text("Every 12 Months");
  });

  $("#beam-button").click(function() {
    $("#wipertype-preview").text("Beam");
  });

  $("#hybrid-button").click(function() {
    $("#wipertype-preview").text("Hybrid");
  });

  $(".remove-vehicle-button").click(function() {
    let vehicleId = $(this).val();
    removeVehicle(vehicleId);

    vehicleCount -= 1;
    if(vehicleCount < 0) {
      $("#continue_button").prop('disabled', true);
    }    
  });

  // $("#review_button").click(function() {
  //   validateInput = false;
  //   //Hide the button
  //   $("#review_button").hide();

  //   //Set the submit input to false
  //   $("#submit").val("false");

  //   //Hide the preview
  //   $("#vehicle_preview").hide();

  //   //Go to the review step and disable all the other steps
  //   $('#smartwizard').smartWizard("goToStep", 3);
  //   $('#smartwizard').smartWizard("stepState", [0], "disable");
  //   $('#smartwizard').smartWizard("stepState", [1], "disable");
  //   $('#smartwizard').smartWizard("stepState", [2], "disable");
  // });

  $("#remove_current_vehicle").click(function() {
    //Disable the previous steps
    $('#smartwizard').smartWizard("stepState", [0], "disable");
    $('#smartwizard').smartWizard("stepState", [1], "disable");
    $('#smartwizard').smartWizard("stepState", [2], "disable");

    //Set the submit input to false
    $("#submit").val("false");

    //Hide the preview
    $("#vehicle_preview").hide();

    vehicleCount -= 1;
    if(vehicleCount < 0) {
      $("#continue_button").prop('disabled', true);
    }
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

  if($("#num_vehicles").val() != '0') {
    if($("#new_vehicle").val() == 'false') {
      $('#smartwizard').smartWizard("goToStep", 3);
      $('#smartwizard').smartWizard("stepState", [0], "disable");
      $('#smartwizard').smartWizard("stepState", [1], "disable");
      $('#smartwizard').smartWizard("stepState", [2], "disable");

      //Set the submit input to false
      $("#submit").val("false");

      //Hide the preview
      $("#vehicle_preview").hide();
    }
    else {
      $("#smartwizard").on("stepContent", function(e, anchorObject, stepIndex, stepDirection) {
        validatePage(stepIndex, stepDirection);
      });
    }
  }
  else {
    $("#smartwizard").on("stepContent", function(e, anchorObject, stepIndex, stepDirection) {
      validatePage(stepIndex, stepDirection);
    });
  }
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