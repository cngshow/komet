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
var ModalFormValidatorModule = (function() {
    function on_shown_focus_ujs(modal_id) {
        // set focus to the first visible form element in a modal popup
        $("#" + modal_id).on('shown.bs.modal', function () {
            var modal_form = $(this).find("form");
            var firstInput = $(":input:not(input[type=button],input[type=submit],button):visible:first", modal_form);
            firstInput.focus();
        });
    }

    // this validates the modal form setting up the error placement
    function validator(form_id) {
        return $('#' + form_id).validate({
            errorPlacement: function (error, element) {
                console.log(error);
                // console.log(element.attr('id'));
                // var lbl = $("label[for='" + element.attr('id') + "']");
                // error.insertAfter(lbl);
            }
        });
    }

    function reset_modal_form(form_id) {
        validator(form_id).resetForm(); //removed jquery validation errors
        document.getElementById(form_id).reset(); // blanks out the form
    }

    function hide_modal(modal_id) {
        $('#' + modal_id).modal('hide'); //closes the modal
    }

    function show_modal(modal_id) {
        $('#' + modal_id).modal('show'); //closes the modal
    }

    return {
        validator: validator,
        on_shown_focus_ujs: on_shown_focus_ujs,
        hide_modal: hide_modal,
        show_modal: show_modal,
        reset_modal_form: reset_modal_form
    }
})();
