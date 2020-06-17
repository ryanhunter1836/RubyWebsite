// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

require("@rails/ujs").start()
require("turbolinks").start()
require("@rails/activestorage").start()
require("channels")

// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//
// const images = require.context('../images', true)
// const imagePath = (name) => images(name, true)

import 'bootstrap'
import 'smartwizard/dist/js/jquery.smartWizard.min.js'

$(document).on('turbolinks:load', function() {
  $('#smartwizard').smartWizard({
    theme: 'arrows',
    justified: true,
    enableURLhash: false,
    transitionEffect: 'fade',
    keyNavigation: false,
    autoAdjustHeight: false,
    toolbarSettings: {
      toolbarPosition: 'bottom',
      toolbarButtonPosition: 'left'
    },
    anchorSettings: {
      removeDoneStepOnNavigateBack: true,
      anchorClickable: false
    }
  });

  $('#make-selector').change(function() {
    var make_id = $(this).val();
    $.get( "/get_models_by_make", { id: make_id }, function( data ) {
      $("#model-selector").html("");
      $("#order_option_vehicle_id").html("");
      //Include a blank row
      $("#model-selector").append( "<option value label=\" \"</option>" );
      $.each( data, function( index, value ) {
        $("#model-selector").append( "<option value='" + value.id + "'>" + value.model + "</option>" );
      });
    });
  });
  
  // Listen for the model selector changing
  $('#model-selector').change(function() {
    var make_id = $(this).val();
    $.get( "/get_years_by_model", { id: make_id }, function( data ) {
      $("#order_option_vehicle_id").html("");
      //Include a blank row
      $("#order_option_vehicle_id").append( "<option value label=\" \"</option>" );
      $.each( data, function( index, value ) {
        $("#order_option_vehicle_id").append( "<option value='" + value.id + "'>" + value.year + "</option>" );
      });
    });
  });
})
