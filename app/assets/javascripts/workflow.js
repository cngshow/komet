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
    var dialog, form;

    function init() {

        this.overviewSetsGridOptions = null;
        this.overviewItemsGridOptions = null;

        // line below hiding view concept and view history gird which is displayed on workflow dashboard
        $('#komet_view_concept_form').hide();

        //code below is used to open create workflow dialog window
        dialog = $("#komet_workflow_form").dialog({
            autoOpen: false,
            closeOnEscape: false,
            position: { my: "right top", at: "left bottom", of: "#komet_user_preference_link" },
            height: 350,
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
                "Save workflow": saveworkflow, // save work flow. saveworkflow is a function defined below
                Cancel: function() {
                    dialog.dialog( "close" ); // cancel work flow
                }
            },
            close: function() {
                form[ 0 ].reset();

            }
        });

        // start work flow button click. this button is located on taxaonomy dashboard footer
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
        $("#komet_workflow_create_form").validate({
            // rules: {
            //     db_name: {
            //         required: true,
            //         alphas_only: true
            //     },
            //     db_version: {
            //         required: true,
            //         alphas_only: true
            //     },
            //     db_description: {
            //         required: true,
            //         trim_whitespace: true
            //     },
            //     artifact_classifier: {
            //         alphas_only: true
            //     }
            // },
            errorPlacement: function (error, element) {
                var lbl = $("label[for='" + element.attr('id') + "']");
                // error.addClass('arrow_box');
                error.insertAfter(lbl);
            }
        });
        if ($("#komet_workflow_create_form").valid()) {
            //this function saves workflow. Create workflow works
            var name = $( "#txtWorkflow_Name" ).val();
            var description = $( "#txtWorkflow_Description" ).val();
            var params = {name: name, description: description};

            $.post( gon.routes.taxonomy_create_workflow_path, params, function( results ) {
                dialog.dialog( "close" ); //closing dialog
                location.replace(gon.routes.komet_dashboard_dashboard_path);
            });
        }
    }

    function loadOverviewItemsGrid (){
        $('#komet_view_concept_form').hide();
        // If a grid already exists destroy it or it will create a second grid
        if (this.overviewSetsGridOptions) {
            this.overviewSetsGridOptions.api.destroy();
        }
        // set the options for the result grid
        this.overviewItemsGridOptions = {
            rowHeight: 35,
            enableColResize: true,
            enableSorting: true,
            suppressCellSelection: true,
            rowSelection: "single",
            onGridReady: this.onGridReady,
            rowModelType: 'pagination',
            columnDefs: [
                {field: "process_id", headerName: 'ProcessID', hide: 'true' },
                {field: "name", headerName: 'Name'},
                {field: "description", headerName: "Description"},
                {field: "status", headerName: "Status" ,width:130},
                {field: "viewhistory", headerName: "" ,width:120},
                {field: "viewconcept", headerName: "" ,width:120},
                {field: "release", headerName: "" ,width:120},

            ]
        };

        new agGrid.Grid($("#komet_workflow_overview_items").get(0), this.overviewItemsGridOptions);

        this.getOverviewItemsData();
    }

    function getOverviewItemsData  (){

        // load the parameters from the form to add to the query string sent in the ajax data call
        var page_size = $("#komet_workflow_overview_page_size").val();
        var filter = $("#komet_workflow_overview_sets_filter").val();

        var searchParams = "?overview_page_size=" + page_size;

        if (filter != null) {
            searchParams += "overview_sets_filter=" + filter;
        }

        var pageSize = Number(page_size);

        // set the grid datasource options, including processing the data rows
        var dataSource = {

            pageSize: pageSize,
            getRows: function (params) {

                var pageNumber = params.endRow / pageSize;
                searchParams += "&overview_items_page_number=" + pageNumber ;

                // make an ajax call to get the data
                $.get(gon.routes.workflow_get_advanceable_process_information_path + searchParams, function (search_results) {
                       this.overviewItemsGridOptions.api.setColumnDefs(this.overviewItemsGridOptions.columnDefs);

                    params.successCallback(search_results.data, search_results.total_number);
                }.bind(this));
            }.bind(this)
        };

        this.overviewItemsGridOptions.api.setDatasource(dataSource);
    }

    function onGridReady (event){
        event.api.autoSizeColumns();
    }

    function cancel_advancement() {
        reset_modal();
    }

    function advance_workflow() {
        $('#wfl_modal_form').validate({
            errorPlacement: function (error, element) {
                var lbl = $("label[for='" + element.attr('id') + "']");
                error.insertAfter(lbl);
            }
        });

        if ($('#wfl_modal_form').valid()) {
            //submit the form to transition the workflow

            reset_modal();
        }
    }

    function reset_modal() {
        //reset the dropdown in the footer to the default and close the modal
        $('#komet_workflow_transition').val('');
        $('#wfl_modal').modal('toggle');
    }

    function release(uuid) {
        alert('releasing ' + uuid + '. we need to add the conditional so this action only happens with claimed workflows...those with the lock/unlock');
    }
   function hideWindow() // div container which show concept and history has x to close window. see line no 35 in dash_workflow.html
    {
        $('#komet_workflow_concept').hide();
        $("#komet_workflow_overview_items").css('width', '100%');
    }

    function showTaxonomy(process_id) {// when user clicks on workflow name it navigate users to the taxonomy dashboard
        // todo - popup a message about using the workflow and redirecting...
        console.log('calling set_user_workflow');
        $.get(gon.routes.workflow_set_user_workflow_path, {process_id: process_id}, function() {
            console.log('going to komet dashboard');
            location.replace('/komet_dashboard/dashboard');
        });
    }

    function showHistory(process_Id) {

        // $("#workflow_concept_grid").html(""); // empty grid giv in concept grid (displayed on RHS of workflow dashboard page)
        //
        // //destroying the grid before rebuilding it
        // if (this.conceptSetsGridOptions) {
        //     this.conceptSetsGridOptions.api.destroy();
        // }
        //
        // // set the options for the result grid
        // this.conceptItemsGridOptions = {
        //     enableColResize: true,
        //     enableSorting: true,
        //     suppressCellSelection: true,
        //     rowSelection: "single",
        //     onGridReady: this.onGridReady,
        //     rowModelType: 'pagination',
        //     columnDefs: [
        //         // todo this is an example of defining column once you have actual data to populate grid.
        //         // {field: "description", headerName: "Description"},
        //         { headerName: 'Concept name'}, //as per firefram this grid has only 2 columns
        //         { headerName: "Timestamp"},
        //
        //     ]
        // };
        //
        // new agGrid.Grid($("#workflow_concept_grid").get(0), this.conceptItemsGridOptions);
        //
        $("#komet_workflow_overview_items").css('width', '50%');
        $('#komet_workflow_concept').css('width', '50%').show(200);

        // this code below is for view history or history in  view concept - dashboard workflow
        var args = arguments;
        var getHistorydata = "";
        $.get(gon.routes.workflow_get_history_path, {processId: process_Id}, function (results) {
            $.each(results, function (index, value) {
                if (index == 0)
                {
                    $('#komet-workflow_username_display').html(value.userId);
                    $('#komet-workflow_date_display').html(value.timeAdvanced );
                    $('#komet-workflow_action_display').html(value.action);
                }

                getHistorydata = '<div class="komet-workflow-set-definition-row">' ;
                getHistorydata +='<div class="komet-workflow-history-item"><label for="workflow_user">Workflow User:</label><div>' + value.userId +'</div></div>';
                getHistorydata +='<div class="komet-workflow-history-item"><label for="workflow_time">Time:</label><div>' + value.timeAdvanced +'</div></div>';
                getHistorydata +='<div class="komet-workflow-history-item"><label for="workflow_starting_state">Starting State:</label><div>' + value.initialState +'</div></div>';
                getHistorydata += '</div><div class="komet-workflow-set-definition-row">' ;
                getHistorydata +='<div class="komet-workflow-history-item"><label for="workflow_action">Action:</label><div>' + value.action +'</div></div>';
                getHistorydata +='<div class="komet-workflow-history-item"><label for="workflow_resulting_state">Resulting State:</label><div>'+  value.outcomeState +'</div></div>';
                getHistorydata += '</div><div class="komet-workflow-set-definition-row">' ;
                getHistorydata +='<div class="komet-workflow-history-item"><label for="workflow_comment">Comment:</label><div>' + value.comment + '</div></div></div>';
               // getHistorydata = '<div class="komet-mapping-set-definition-row">' ;
                getHistorydata +='<hr class="komet-concept-details-hr">';
            })
            $('#workflow_history').html (getHistorydata);

            if (args[1] === undefined) {
                showConcept(process_Id, false);
            }
        });
    }

    function set_name_and_description(results) {
        $('#komet-workflow_name_display').html(results.name);
        $('#komet-workflow_description_display').html(results.description);
        $('#komet-workflow_creator_display').html(results.creatorId);
    }

    function showConcept(process_Id)  // this function populates data when user clicks on View concept link from workflow dashboard grid
    {
        var args = arguments;

       $.get(gon.routes.workflow_get_process_path, {processId: process_Id}, function( results ) {
           set_name_and_description(results);

           if (args[1] === undefined) {
               showHistory(process_Id, false);
           }
       });

        // $("#workflow_concept_grid").html(""); // empty grid giv in concept grid (displayed on RHS of workflow dashboard page)
        //
        // //destroying the grid before rebuilding it
        // if (this.conceptSetsGridOptions) {
        //     this.conceptSetsGridOptions.api.destroy();
        // }
        //
        // // set the options for the result grid
        // this.conceptItemsGridOptions = {
        //     enableColResize: true,
        //     enableSorting: true,
        //     suppressCellSelection: true,
        //     rowSelection: "single",
        //     onGridReady: this.onGridReady,
        //     rowModelType: 'pagination',
        //     columnDefs: [
        //         // todo this is an example of defining column once you have actual data to populate grid.
        //      // {field: "description", headerName: "Description"},
        //         { headerName: 'Concept name'}, //as per firefram this grid has only 2 columns
        //         { headerName: "Timestamp"},        //
        //     ]
        // };
        //
        // new agGrid.Grid($("#workflow_concept_grid").get(0), this.conceptItemsGridOptions);
        //
        // //todo need to write code to populated data once above rest api call on line 268 works. Code above this line builds empty grid with column name;
        $('#komet_view_concept_form').show(200);

    }

    return {

        initialize: init,
        loadOverviewItemsGrid:loadOverviewItemsGrid,
        getOverviewItemsData:getOverviewItemsData,
        showConcept:showConcept,
        hideWindow:hideWindow,
        showTaxonomy:showTaxonomy,
        showHistory:showHistory,
        release: release,
        cancel_advancement: cancel_advancement,
        advance_workflow: advance_workflow
    };
})();