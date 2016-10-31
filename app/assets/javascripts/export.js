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
var ExportModule = (function () {
    function init() {
        $("#start_date").datepicker({
            constrainInput: true,
            maxDate: -1
        });
        $("#end_date").datepicker({
            constrainInput: true,
            maxDate: 0
        });
        $("#end_date").prop('disabled', true);
        $("#end_date").datepicker("option", "minDate", null);

        $("#start_date").change(function (eventObject) {
            $("#end_date").datepicker("option", "minDate", $(this).datepicker( "getDate" ));
            $("#end_date").prop('disabled', false);
        });
        $('#processing_msg').hide();
        $('#buttons_div').show();
    }

    function cancel_export() {
        ModalFormValidatorModule.reset_modal_form('export_modal_form');
        ModalFormValidatorModule.hide_modal('export_modal');
    }

    function submit_export() {
        // ModalFormValidatorModule.validator('export_modal_form');
        // var form = $('#export_modal');
        // var start_date = $('#start_date').val();
        var start_date = $("#start_date").datepicker( "getDate" );

        // if (form.valid()) {
            //submit the form to transition the workflow
            // form.submit();

        if (start_date == null) {
            alert('please select a start date for this export');
            $("#start_date").focus();
            return false;
        }

        // hide the cancel and submit buttons
        $('#buttons_div').hide();
        $('#processing_msg').show();

        // select the parameters to pass to the rest call
        var end_date = $("#end_date").datepicker( "getDate" );
        var params = {start_date: start_date, end_date: end_date};
        window.location.href = gon.routes.export_path + '?' + jQuery.param(params)
        ModalFormValidatorModule.reset_modal_form('export_modal_form');
        ModalFormValidatorModule.hide_modal('export_modal');
    }

    return {
        initialize: init,
        cancel_export: cancel_export,
        submit_export: submit_export
    };
})();
