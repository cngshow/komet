var VUIDRequest = (function () {

    var requestWindow = null;

    function openRequestDialog() {

        //requestWindow = window.open(url, "VUIDRequest", "width=1200,height=800");

        var formID = "komet_vuid_request_form";

        var formString = '<form action="' + gon.routes.taxonomy_get_generated_vhat_ids_path + '" id="' + formID + '" class="komet-vuid-request-form">'
            + '<div class="komet-row"><label for="komet_vuid_request_number">Number of VUIDs:</label><input id="komet_vuid_request_number" name="number_of_vuids" type="number" class="form-control" value="1"></div>'
            + '<div class="komet-row"><label for="komet_vuid_request_reason">Reason for Request:</label><textarea id="komet_vuid_request_reason" name="reason" class="form-control"></textarea></div>'
            + '<button type="submit" class="btn btn-primary form-control" id="komet_vuid_request_submit">Generate VUIDs</button></form><hr>'
            + '<div id="komet_vuid_request_table"><div class="komet-row komet-table-header"><div class="komet-vuid-request-table-vuid">VUID</div>'
            + '</div><div id="komet_vuid_request_table_body" class="komet-table-body"></div></div>';

        var dialogID = "komet_vuid_request_dialog";
        var dialogString = '<div id="' + dialogID + '"><div class="komet-vuid-request-dialog-body">' + formString + '</div></div>';

        $("body").prepend(dialogString);

        var dialog = $("#" + dialogID);

        dialog.dialog({
            beforeClose: function () {
                dialog.remove();
            },
            open: function () {

                // put focus on the first input field
                var request_number = $("#komet_vuid_request_number").focus();
                var reason = $("#komet_vuid_request_reason");

                // add a function to handle the form submission
                $("#" + formID).submit(function () {

                    // clear any current page messages
                    UIHelper.removePageMessages(dialog);

                    var errors = false;

                    // check to see if the request number is a valid number and generate an error message if it isn't
                    if (request_number.val() < 1 ){

                        request_number.before(UIHelper.generatePageMessage("The 'Number of VUIDs' field must be a valid number greater then 0."));
                        errors = true;
                    }

                    // check to see if the reason is filled in and generate an error message if it isn't
                    if (reason.val() == "" || reason.val().length > 30){

                        reason.before(UIHelper.generatePageMessage("The 'Reason' field can not be blank and must be no more than 30 characters."));
                        errors = true;
                    }

                    // if there were errors stop processing the form and return false to stop the form from submitting
                    if (errors){
                        return false;
                    }

                    // make the ajax call
                    $.ajax({
                        type: "POST",
                        url: $(this).attr("action"),
                        data: $(this).serialize(),
                        success: function (data) {

                            console.log(data);

                            var tableBody = $('#komet_vuid_request_table_body');
                            var tableString = "";

                            // if the return has startInclusive then loop thru the start and end numbers and generate a row for each. Otherwise an error occurred and display that
                            if (data.hasOwnProperty("startInclusive")){

                                for (var i = data.startInclusive; i <= data.endInclusive; i++){

                                    tableString += '<div class="komet-row"><div class="komet-vuid-request-table-vuid">' + i + '</div><div class="komet-vuid-request-table-copy">'
                                        + '<button type="button" onclick="UIHelper.copyToClipboard(\'' + i + '\', \'komet_vuid_request_dialog\')" class="komet-vuid-request-table-copy-button form-control" aria-label="Copy VUID ' + i + ' to Clipboard">'
                                        + 'Copy to Clipboard</button></div></div>';
                                }
                            } else {
                                tableString = UIHelper.generatePageMessage(data)
                            }

                            // display the results
                            tableBody.html(tableString);
                        }
                    });

                    // have to return false to stop the form from posting twice.
                    return false;
                });
            },
            title: "Generate VUIDs",
            resizable: false,
            height: 500,
            width: 500,
            modal: true,
            position: {my: "right bottom", at: "left bottom", of: $("#komet_generate_vuid_link")},
            dialogClass: "komet-confirmation-dialog komet-dialog-no-close-button",
            buttons: {
                Close: {
                    "class": "btn btn-default",
                    text: "Close",
                    click: function () {
                        $(this).dialog("close");
                    }
                }
            }
        });
    }

    return {
        openRequestDialog: openRequestDialog
    };

})();
