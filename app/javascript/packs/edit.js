document.addEventListener('turbolinks:before-render', () => {
  Components.unloadAll(); 
});



function updateShippingPreview() {
    result = $("#address1_field").val() + " ";
    result += $("#address2_field").val() + "<br/>";
    result += $("#city_field").val() + " ";
    result += $("#state_field").val() + " ";
    result += $("#postal_field").val();
    $("#shipping_preview").html(result);
}

//Functions to update the preview container
function updateVehiclePreview(index) {
  make = $("#make-selector-" + index + " option:selected").text();
  model = $("#model-selector-" + index + " option:selected").text();
  year = $("#vehicle-id-" + index + " option:selected").text();

  $("#vehicle_preview_" + index).text(year + " " + make + " " + model);
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

function toggleVehicle(index) {
  console.log("Event fired");
    //Hide the vehicle
    element = $(".vehicle-form")[index];
    $(element).toggle();
    //Disable the element so it isn't submitted to the server
    elementName = "#vehicle-id-" + (index + 1);
    $(elementName).prop('disabled', function(i, v) { return !v; });
    //Replace with undo button
    element = $(".undo-button")[index];
    $(element).toggle();
    //Remove or show the vehicle on the preview page
    elementName = "#vehicle_preview_" + (index + 1);
    $(elementName).toggle();
}

function updateQualityPreview(qualityString) {
  $("#quality_preview").text(qualityString);
}

function updateFrequencyPreview(frequencyString) {
  $("#frequency_preview").text(frequencyString);
}

function addListeners() {
  //Put a listener on everything
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

  //Hide the vehicle and display an "Undo" button
  $("#remove_button_1").click(function() {
      toggleVehicle(0);
  })

  $("#remove_button_2").click(function() {
      toggleVehicle(1);
  })

  $("#remove_button_3").click(function() {
      toggleVehicle(2);
  })

  $(".undo-button").each(function(index) {
      $(this).click(function() {
          toggleVehicle(index);
      });
  });
}

document.addEventListener('turbolinks:load', () => {
  addListeners();
});

addListeners();