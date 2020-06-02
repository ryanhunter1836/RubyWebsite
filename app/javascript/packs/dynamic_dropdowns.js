import 'smartwizard/dist/js/jquery.smartWizard.min.js'

$( document ).on('turbolinks:load', function() {
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
})

$( document ).on('turbolinks:load', function() {
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
  });
  
  $( document ).on('turbolinks:load', function() {
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
  });