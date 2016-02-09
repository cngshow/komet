// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require jquery-ui
//= require_tree ../../../vendor/assets/javascripts/jquery-svg
//= require_tree ../../../vendor/assets/javascripts/jsTree
//= require_tree ../../../vendor/assets/javascripts/jq-ui-plugins
//= require_tree ../../../vendor/assets/javascripts/jquery-tiny-pubsub
//= require bootstrap
//= require turbolinks
//ensure everything in the util directory is loaded before our other javascript
//= require util/common
//= require util/channels
//= require util/svg_helper.js
// Can also do this as long as we have no load order dependencies in the util directory (Currently we do not)
// require_tree ./util
//= require_tree .
