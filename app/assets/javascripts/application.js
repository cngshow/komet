/*
Copyright Notice

 This is a work of the U.S. Government and is not subject to copyright
 protection in the United States. Foreign copyrights may apply.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */
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
//= require jquery2
//= require jquery_ujs
//= require jquery-ui
//= require moment.js
//= require ag-grid.min.js
//= require jquery.enhsplitter
//= require jquery.minicolors
//= require jquery.contextMenu.min.js
//= require_tree ../../../vendor/assets/javascripts/jquery-svg
//= require_tree ../../../vendor/assets/javascripts/jsTree
//= require_tree ../../../vendor/assets/javascripts/jquery-tiny-pubsub
//= require bootstrap
//= require turbolinks
//ensure everything in the util directory is loaded before our other javascript
//= require util/common
//= require util/channels
//= require util/svg_helper.js
// require util/ajax_cache.js
// Can also do this as long as we have no load order dependencies in the util directory (Currently we do not)
// require_tree ./util
//= require_tree .
