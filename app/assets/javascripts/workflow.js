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
    var dialog, form

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
            height: 300,
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

        //show start button at taxaonomy footer if the processid is not passed as querystring in url
        // and hide edit controls show edit controls when processid is passed in querystring
        // when user navigates from workflow dasbboard - workflow name onclick
        if ($('#processid').val() != "")  {
            $('#startbtn').hide();
            $('#editdiv').show();
        }
        else {
            $('#startbtn').show();
            $('#editdiv').hide();
        }

    }

    function saveworkflow()
    {
        //this function saves workflow. Create workflow works
        var processedID=0;
        var name= $( "#txtWorkflow_Name" ).val();
        var description = $( "#txtWorkflow_Description" ).val();
        params = {name:name,description:description}
        $.post( gon.routes.taxonomy_create_workflow_path , params, function( results ) {
            // create_workflow rest api call line 32 in workflow_controller.rb
            processedID = results.value;
        });

         dialog.dialog( "close" ); //closing dialog
        location.replace('/komet_dashboard/dashboard?processID=' + process_Id)
        //todo there is problem with rest api. see line no 60 in workflow_controller.rb
        //populates dropdown on workflow footer. At this point all the edit controls needs to show and be acitve

        /* var params = "?processId=" + processedID + "&wfUser=12345"
         $.get(gon.routes.workflow_get_transition_path + params, function( results ) {
             $.each(results,function(index,value) {
                 $("#komet_workflow_transition").append($("<option />").val(value.id).text(value.action));
             });
           });

             $.get(gon.routes.workflow_get_process_path + "?processId=" + processedID, function( results ) {
                $.each(results,function(index,value) {
                 $("komet_workflow_name").val(value.name)
                 $("komet_Edit_workflow").val(value.processStatus.name)
                });
            }); */

    }
    function loadOverviewItemsGrid (){
        $('#komet_view_concept_form').hide();
        // If a grid already exists destroy it or it will create a second grid
        if (this.overviewSetsGridOptions) {
            this.overviewSetsGridOptions.api.destroy();
        }
        // set the options for the result grid
        this.overviewItemsGridOptions = {
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

            ]
        };

        new agGrid.Grid($("#komet_workflow_overview_items").get(0), this.overviewItemsGridOptions);

        this.getOverviewItemsData();
    };

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
    };


    function onGridReady (event){
        event.api.autoSizeColumns();
    };

   function hideWindow() // div container which show concept and history has x to close window. see line no 35 in dash_workflow.html
    {
        $('#komet_view_concept_form').hide();
    }
    function showTaxaonomy(process_Id)// when user clicks on workflow name it navigate users to the taxaonomy dashboard
    {
        location.replace('/komet_dashboard/dashboard?processID=' + process_Id)
    }

    function showHistroy(process_Id)
    {

        //todo this call is commented out because rest api call has a bug. showhistory and showconcept pretty much same code
        // i am using build from yesterday - 10/13 rest api call used in this function
        // has a bug. I replicated error and showed/proved to jesse that error is on rest asp call side
        // Joel is working on fixing it. . this function populates data when user clicks on View concept link
        // from workflow dashboard grid

        var paramsProcess = "?processId=" + process_Id ;
        // $.get(gon.routes.workflow_get_process_path + paramsProcess, function( results ) {
        // $('#komet-workflow_name_display').html(results.name);
        // $('#komet-workflow_description_display').html(results.description);
        // $('#komet-workflow_author_display').html(results.creatorId);
        // $('#komet-workflow_reviewer_approver_display').html("NA");
        // });
        // todo please remove this test data below once above rest api call works
        $('#komet-workflow_name_display').html(" processID for testing div onclick action" + process_Id);
        $('#komet-workflow_description_display').html("Need Data");
        $('#komet-workflow_author_display').html("Need Data");
        $('#komet-workflow_reviewer_approver_display').html("Need Data");

        $("#workflow_concept_grid").html(""); // empty grid giv in concept grid (displayed on RHS of workflow dashboard page)

        //destroying the grid before rebuilding it
        if (this.conceptSetsGridOptions) {
            this.conceptSetsGridOptions.api.destroy();
        }

        // set the options for the result grid
        this.conceptItemsGridOptions = {
            enableColResize: true,
            enableSorting: true,
            suppressCellSelection: true,
            rowSelection: "single",
            onGridReady: this.onGridReady,
            rowModelType: 'pagination',
            columnDefs: [
                // todo this is an example of defining column once you have actual data to populate grid.
                // {field: "description", headerName: "Description"},
                { headerName: 'Concept name'}, //as per firefram this grid has only 2 columns
                { headerName: "Timestamp"},

            ]
        };

        new agGrid.Grid($("#workflow_concept_grid").get(0), this.conceptItemsGridOptions);

        //todo need to write code to populated data once above rest api call on line 201 works. Code above this line builds empty grid with column name;
        $('#komet_view_concept_form').show(200);


        // this code below is for view history or history in  view concept - dashboard workflow
        var paramsProcess = "?processId=" + process_Id ;
        // $.get(gon.routes.workflow_get_history_path + paramsProcess, function( results ) {
        // $('#komet_history-workflow_description_display').html(results.name);
        // $('#komet-workflow_description_display').html(results.description);
        // $('#komet_history-workflow_author_display').html(results.creatorId);
        // $('#komet_history-workflow_reviewer_approver_display').html("NA");
        // });
        // todo please remove this test data below once above rest api call works
        $('#komet_history-workflow_name_display').html(" processID for testing div onclick action" + process_Id);
        $('#komet_history-workflow_description_display').html("Need Data");
        $('#komet_history-workflow_author_display').html("Need Data");
        $('#komet_history-workflow_reviewer_approver_display').html("Need Data");

    }
    function showConcept(process_Id)  // this function populates data when user clicks on View concept link from workflow dashboard grid
    {
       //todo this call is commented out because rest api call has a bug.
        // i am using build from yesterday - 10/13 rest api call used in this function
        // has a bug. I replicated error and showed/proved to jesse that error is on rest asp call side
        // Joel is working on fixing it. . this function populates data when user clicks on View concept link
        // from workflow dashboard grid

        var paramsProcess = "?processId=" + process_Id ;
       // $.get(gon.routes.workflow_get_process_path + paramsProcess, function( results ) {
           // $('#komet-workflow_name_display').html(results.name);
           // $('#komet-workflow_description_display').html(results.description);
           // $('#komet-workflow_author_display').html(results.creatorId);
           // $('#komet-workflow_reviewer_approver_display').html("NA");
       // });
        // todo please remove this test data below once above rest api call works
        $('#komet-workflow_name_display').html(" processID for testing div onclick action" + process_Id);
        $('#komet-workflow_description_display').html("Need Data");
        $('#komet-workflow_author_display').html("Need Data");
        $('#komet-workflow_reviewer_approver_display').html("Need Data");

        $("#workflow_concept_grid").html(""); // empty grid giv in concept grid (displayed on RHS of workflow dashboard page)

        //destroying the grid before rebuilding it
        if (this.conceptSetsGridOptions) {
            this.conceptSetsGridOptions.api.destroy();
        }

        // set the options for the result grid
        this.conceptItemsGridOptions = {
            enableColResize: true,
            enableSorting: true,
            suppressCellSelection: true,
            rowSelection: "single",
            onGridReady: this.onGridReady,
            rowModelType: 'pagination',
            columnDefs: [
                // todo this is an example of defining column once you have actual data to populate grid.
             // {field: "description", headerName: "Description"},
                { headerName: 'Concept name'}, //as per firefram this grid has only 2 columns
                { headerName: "Timestamp"},

            ]
        };

        new agGrid.Grid($("#workflow_concept_grid").get(0), this.conceptItemsGridOptions);

        //todo need to write code to populated data once above rest api call on line 268 works. Code above this line builds empty grid with column name;
        $('#komet_view_concept_form').show(200);


        // this code below is for view history or history in  view concept - dashboard workflow
        var paramsProcess = "?processId=" + process_Id ;
        // $.get(gon.routes.workflow_get_history_path + paramsProcess, function( results ) {
        // $('#komet_history-workflow_description_display').html(results.name);
        // $('#komet-workflow_description_display').html(results.description);
        // $('#komet_history-workflow_author_display').html(results.creatorId);
        // $('#komet_history-workflow_reviewer_approver_display').html("NA");
        // });
        // todo please remove this test data below once above rest api call works
        $('#komet_history-workflow_name_display').html(" processID for testing div onclick action" + process_Id);
        $('#komet_history-workflow_description_display').html("Need Data");
        $('#komet_history-workflow_author_display').html("Need Data");
        $('#komet_history-workflow_reviewer_approver_display').html("Need Data");
    }

    return {

        initialize: init,
        loadOverviewItemsGrid:loadOverviewItemsGrid,
        getOverviewItemsData:getOverviewItemsData,
        showConcept:showConcept,
        hideWindow:hideWindow,
        showTaxaonomy:showTaxaonomy,
        showHistroy:showHistroy


    };

})();