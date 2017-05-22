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
var PreferenceModule = (function () {

    var refsetList = {};
    var refsetRows = [];
    var rowCount = 0;

    function loadPreferences() {

        Common.cursor_wait();

        // make an ajax call to get the data for user preferences and pass it the name of a partial file to render
        $.get(gon.routes.taxonomy_get_user_preference_info_path, {partial: 'komet_dashboard/user_preferences'}, function (data) {

            try {

                var documentFragment = document.createRange().createContextualFragment(data);
                $('#komet_main_navigation').after(documentFragment);

                Common.cursor_auto();
            }
            catch (err) {

                console.log("*******  ERROR **********");
                console.log(err.message);
                Common.cursor_auto();
                throw err;
            }
        });
    }

    function init(stampDateValue) {

        // setup the tabs
        $("#komet_preferences_tabs").tabs();

        var stampDateField = $('#komet_preferences_stamp_date');

        // initialize the STAMP date field
        UIHelper.initDatePicker("#komet_preferences_stamp_date", stampDateValue);

        var dialog = $("#komet_user_preference_form");
        var form = dialog.find("form");

        // create the dialog form
        dialog.dialog({
            autoOpen: false,
            closeOnEscape: false,
            position: {my: "right top", at: "left bottom", of: "#komet_user_preference_link"},
            height: 650,
            width: 650,
            dialogClass: "no-close",
            modal: true,
            buttons: {
                "Apply changes": function() {
                    dialog.find("form").submit();
                },
                Cancel: function() {
                    dialog.remove();
                }
            },
            close: function() {
                dialog.remove();
            }
        });

        form.submit(function () {

            Common.cursor_wait();
            UIHelper.removePageMessages(form);

            $.ajax({
                type: "POST",
                url: $(this).attr("action"),
                data: $(this).serialize() + "&time=" + PreferenceModule.getStampDate(),
                error: function (){Common.cursor_auto();},
                success: function (data) {

                    location.replace(gon.routes.komet_dashboard_dashboard_path);
                }
            });

            // have to return false to stop the form from posting twice.
            return false;
        });

        dialog.parent().children().children(".ui-dialog-titlebar-close").remove();

        dialog.dialog("open");

        // initialize all order control widgets on the page
        UIHelper.initOrderControls(dialog);

        // initialize all flag control widgets on the page
        UIHelper.initFlagControls(dialog);

        UIHelper.processAutoSuggestTags(dialog);
    }


    function getStampDate(){

        var stamp_date = $('#komet_preferences_stamp_date').find("input").val();

        if (stamp_date == '') {
            return 'latest';
        } else {
            return new Date(stamp_date).getTime().toString();
        }
    }

    return {

        loadPreferences: loadPreferences,
        initialize: init,
        getStampDate: getStampDate
    };

})();