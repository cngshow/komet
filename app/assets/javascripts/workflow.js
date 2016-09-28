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
var WorkflowModule = (function () {


    function init() {
        var dialog, form

        dialog = $("#komet_workflow_form").dialog({
            autoOpen: false,
            closeOnEscape: false,
            position: { my: "right top", at: "left bottom", of: "#komet_user_preference_link" },
            height: 500,
            width: 550,
            dialogClass: "no-close",
            show: {
                effect: "blind",
                duration: 50
            },
            hide: {
                effect: "blind",
                duration: 50
            },
            modal: true,
            buttons: {
                "Save workflow": saveworkflow,
                Cancel: function() {
                    dialog.dialog( "close" );
                }
            },
            close: function() {
                form[ 0 ].reset();

            }
        });


        form = dialog.find( "form" ).on( "submit", function( event ) {
            event.preventDefault();
           // applyChanges();
        });

        $("#startbtn").on( "click", function() {
            dialog.dialog( "open" );
        });


        form = dialog.find( "form" ).on( "submit", function( event ) {
            event.preventDefault();
            saveworkflow();
        });
    }


    function saveworkflow()
    {
        var definitionId = 'definitionId';
        var creatorNid= 12345;
        var name= $( "#txtWorkflow_Name" ).val();
        var description = $( "#txtWorkflow_Description" ).val();
        params = {definitionId:definitionId,creatorNid:creatorNid,name:name,description:description}

        $.post( gon.routes.taxonomy_create_workflow_path , params, function( results ) {
            console.log(results);
        });

        dialog.dialog( "close" );
        location.replace(gon.routes.komet_dashboard_dashboard_path);

    }


    return {

        initialize: init


    };

})();