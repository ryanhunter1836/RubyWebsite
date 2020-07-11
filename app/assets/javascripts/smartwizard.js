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
});