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
//= require jquery-validation/jquery.validate.min
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

// this is for ajax_flash notifications
//= require bootstrap-notify
//= require_tree .

function flash_notify(options, settings) {
    $.notify(options, settings);
}

$( document ).ajaxComplete(function(event, jqXHR, ajaxOptions) {
    var url = ajaxOptions.url;
    var patt = new RegExp(gon.routes.flash_notifier_flash_notifications_path);
    var res = patt.test(url);

    // only make the rest call for routes that are NOT the flash notifier call
    if (! res) {
        $.get(gon.routes.flash_notifier_flash_notifications_path, function (results) {
            //iterate the results calling $.notify
            var arrayLength = results.length;

            for (var i = 0; i < arrayLength; i++) {
                flash_notify(results[i].options, results[i].settings);
            }
        });
    }
});

//** javascript plugin overrides

// turn off the autofocus feature of Jquery UI dialogs
//$.ui.dialog.prototype._focusTabbable = $.noop;

//** javascript polyfills to make sure code works in all browsers, regardless of current support level

// https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/findIndex
if (!Array.prototype.findIndex) {
    Array.prototype.findIndex = function(predicate) {
        'use strict';
        if (this == null) {
            throw new TypeError('Array.prototype.findIndex called on null or undefined');
        }
        if (typeof predicate !== 'function') {
            throw new TypeError('predicate must be a function');
        }
        var list = Object(this);
        var length = list.length >>> 0;
        var thisArg = arguments[1];
        var value;

        for (var i = 0; i < length; i++) {
            value = list[i];
            if (predicate.call(thisArg, value, i, list)) {
                return i;
            }
        }
        return -1;
    };
}