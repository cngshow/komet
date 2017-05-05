var TaxonomySearchModule = (function () {

    var gridOptions;

    function init(view_params) {

        // setup the advanced search options accordion
        $("#taxonomy_search_options_pane").accordion({
            collapsible: true,
            active: true,
            heightStyle: "content",
            animate: false
        });

        var form = $("#komet_taxonomy_search_form");

        form.submit(function () {

            TaxonomySearchModule.loadResultGrid();
            return false;
        });

        $("#taxonomy_search_sememe_fields").hide();
        $("#taxonomy_search_id_fields").hide();

        // load any previous assemblage queries into a menu for the user to select from
        UIHelper.processAutoSuggestTags(form);

        $("#komet_search_tab_trigger").focus(function(){

            if (gridOptions && gridOptions.api.rowModel.rowsToDisplay.length > 0){

                gridOptions.api.ensureIndexVisible(0);
                gridOptions.api.setFocusedCell(0, "matching_concept");
            }
        }.bind(this));

        // initialize the STAMP date field
        UIHelper.initDatePicker("#komet_taxonomy_search_stamp_date", view_params.time);
    }

    function getAllowedStates (){
        return $("#komet_taxonomy_search_allowed_states").val();
    }

    function getStampDate(){

        var stamp_date = $("#komet_taxonomy_search_stamp_date").find("input").val();

        if (stamp_date == '' || stamp_date == 'latest') {
            return 'latest';
        } else {
            return new Date(stamp_date).getTime().toString();
        }
    };

    function getStampModules(){
        return $('#komet_taxonomy_search_stamp_modules').val();
    }

    function getStampPath(){
        return $('#komet_taxonomy_search_stamp_path').val();
    }

    function getViewParams (){
        return {allowedStates: getAllowedStates(), time: getStampDate(), modules: getStampModules(), path: getStampPath()};
    }

    function loadResultGrid() {

        Common.cursor_wait();

        UIHelper.removePageMessages("#komet_taxonomy_search_form");

        if ($("#taxonomy_search_text").val() === ""){

            $("#taxonomy_search_combo_field").after(UIHelper.generatePageMessage("Search Text cannot be blank."));
            return;
        }

        // If a grid already exists destroy it or it will create a second grid
        if (gridOptions){
            gridOptions.api.destroy();
        }

        // set the options for the result grid
        gridOptions = {
            enableColResize: true,
            enableSorting: true,
            suppressCellSelection: false,
            rowSelection: "single",
            onSelectionChanged: onGridSelection,
            onGridReady: onGridReady,
            rowModelType: 'pagination',
            columnDefs:  [
                {field: "id", headerName: 'ID', hide: 'true'},
                {field: "matching_concept", headerName: "Matching Concept", cellRenderer: function(params) {
                    return '<span class="komet-context-menu" data-menu-type="concept" data-menu-uuid="' + params.data.id + '" '
                        + 'data-menu-state="' + params.data.concept_status + '" data-menu-concept-text="' + params.data.matching_concept + '" data-menu-js-object="search">' + params.value + '</span>';
                }},
                {field: "matching_terms", headerName: "Matching Terms"},
                {field: "concept_status", headerName: "Status"},
                {field: "match_score", headerName: "Score", suppressSizeToFit: "false", hide: 'true'}
            ]
        };

        new agGrid.Grid($("#taxonomy_search_results").get(0), gridOptions);
        getResultData();
    }

    function getResultData(){

        // load the parameters from the form to add to the query string sent in the ajax data call
        var search_type = $("#taxonomy_search_type");
        var page_size = $("#taxonomy_search_page_size");

        var searchParams = "?taxonomy_search_text=" + $("#taxonomy_search_text").val() + "&taxonomy_search_page_size=" + page_size.val() + "&taxonomy_search_type=" + search_type.val() + "&" + jQuery.param({view_params: getViewParams()});

        // set only the parameters needed based on the search type
        if (search_type.val() === "descriptions"){
            searchParams += "&taxonomy_search_description_type=" + $("#taxonomy_search_description_type").val();
        } else if (search_type.val() === "sememes"){
            searchParams += "&taxonomy_search_treat_as_string=" + $("#taxonomy_search_treat_as_string").val() + "&taxonomy_search_assemblage_id=" + $("#taxonomy_search_assemblage").val()
                + "&taxonomy_search_assemblage_display=" + $("#taxonomy_search_assemblage_display").val();
        } else {
            searchParams += "&taxonomy_search_id_type=" + $("#taxonomy_search_id_type").val()
        }

        var pageSize = Number(page_size.val());
        gridOptions.paginationPageSize = pageSize;

        // set the grid datasource options, including processing the data rows
        var dataSource = {

            //paginationPageSize: pageSize,
            getRows: function (params) {

                Common.cursor_wait();

                var pageNumber = params.endRow / pageSize;

                searchParams += "&taxonomy_search_page_number=" + pageNumber;

                // make an ajax call to get the data
                var jqxhr = $.get( gon.routes.search_get_search_results_path + searchParams, function( search_results ) {

                    if (search_results.data.length > 0){
                        $("#taxonomy_search_export").show();
                    } else {
                        $("#taxonomy_search_export").hide();
                    }

                    params.successCallback(search_results.data, search_results.total_number);
                    Common.cursor_auto();
                }).fail(function() {
                    Common.cursor_auto();
                });
            }
        };

        gridOptions.api.setDatasource(dataSource);

        // reload the recents menu
        UIHelper.loadAutoSuggestRecents("taxonomy_search_assemblage_recents", null);
    }

    function onGridSelection(){

        var selectedRows = gridOptions.api.getSelectedRows();

        selectedRows.forEach( function(selectedRow, index) {

            console.log('Row with ID ' + selectedRow.id + ' ' + selectedRow.concept_status + '.');

            var viewParams = getViewParams();

            // make sure we pass all instead of inactive or the concept queries won't work
            if (viewParams.allowedStates == "inactive"){
                viewParams.allowedStates = "active,inactive";
            }

            $.publish(KometChannels.Taxonomy.taxonomySearchResultSelectedChannel, [selectedRow.id, viewParams, WindowManager.getLinkedViewerID()]);
        });
    }

    function onGridReady(event){
        event.api.sizeColumnsToFit();
    }

    function changeSearchType(field){

        /* not sure if we want to clear the values when the user switches types
         if (field.value === "descriptions"){

         $("#taxonomy_search_assemblage_id").val("");
         $("#taxonomy_search_assemblage_disply").val("");
         $("#taxonomy_search_treat_as_string").val("false");
         }
         else {
         $("#taxonomy_search_description_type").val("");
         }
         */


        if (field.value === "descriptions") {

            $("#taxonomy_search_option_description_type_fields").show();
            $("#taxonomy_search_sememe_fields").hide();
            $("#taxonomy_search_id_fields").hide();

        } else if (field.value === "sememes") {

            $("#taxonomy_search_option_description_type_fields").hide();
            $("#taxonomy_search_sememe_fields").show();
            $("#taxonomy_search_id_fields").hide();
        } else {

            $("#taxonomy_search_option_description_type_fields").hide();
            $("#taxonomy_search_sememe_fields").hide();
            $("#taxonomy_search_id_fields").show();
        }
    }

    function exportCSV(){

        var gridOptionsExport = {
            columnDefs:  [
                {field: "id", headerName: 'ID'},
                {field: "matching_concept", headerName: "Matching Concept"},
                {field: "matching_terms", headerName: "Matching Terms"},
                {field: "concept_status", headerName: "Status"},
                {field: "match_score", headerName: "Score", suppressSizeToFit: "false"}
            ]
        };

        new agGrid.Grid($("#taxonomy_search_results_export").get(0), gridOptionsExport);

        // load the parameters from the form to add to the query string sent in the ajax data call
        var search_type = $("#taxonomy_search_type");

        var searchParams = "?taxonomy_search_text=" + $("#taxonomy_search_text").val() + "&taxonomy_search_page_number=1&taxonomy_search_page_size=10000000&taxonomy_search_type=" + search_type.val() + "&" + jQuery.param({view_params: getViewParams()});

        // set only the parameters needed based on the search type
        if (search_type.val() === "descriptions"){
            searchParams += "&taxonomy_search_description_type=" + $("#taxonomy_search_description_type").val();
        } else if (search_type.val() === "sememes"){
            searchParams += "&taxonomy_search_treat_as_string=" + $("#taxonomy_search_treat_as_string").val() + "&taxonomy_search_assemblage_id=" + $("#taxonomy_search_assemblage").val()
                + "&taxonomy_search_assemblage_display=" + $("#taxonomy_search_assemblage_display").val();
        } else {
            searchParams += "&taxonomy_search_id_type=" + $("#taxonomy_search_id_type").val()
        }

        // make an ajax call to get the data
        $.get(gon.routes.search_get_search_results_path + searchParams, function( search_results ) {

            gridOptionsExport.api.setRowData(search_results.data);
            gridOptionsExport.api.exportDataAsCsv({allColumns: true});
            gridOptionsExport.api.destroy();
        });
    }

    return {
        initialize: init,
        getAllowedStates: getAllowedStates,
        getStampDate: getStampDate,
        getStampModules: getStampModules,
        getStampPath: getStampPath,
        getViewParams: getViewParams,
        loadResultGrid: loadResultGrid,
        changeSearchType: changeSearchType,
        exportCSV: exportCSV
    };

})();