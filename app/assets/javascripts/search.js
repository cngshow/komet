var TaxonomySearchModule = (function () {

    var newSearch = true;
    var gridOptions;
    var gridOptions_Exprot;
    var totalNoRecords;

    function init() {

        // setup the advanced search options accordion
        $("#taxonomy_search_options_pane").accordion({
            collapsible: true,
            active: true,
            heightStyle: "content",
            animate: false
        });

        var form = $("#komet_taxonomy_search_form");

        form.submit(function () {
            TaxonomySearchModule.loadExportGrid();
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
    }

    function loadResultGrid() {

        UIHelper.removePageMessages("#komet_taxonomy_search_form");

        if ($("#taxonomy_search_text").val() === ""){

            $("#taxonomy_search_combo_field").after(UIHelper.generatePageMessage("Search Text cannot be blank."));
            return;
        }

        newSearch = true;

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
                        + 'data-menu-state="' + params.data.concept_status + '" data-menu-concept-text="' + params.data.matching_concept + '">' + params.value + '</span>';
                }},
                {field: "matching_terms", headerName: "Matching Terms"},
                {field: "concept_status", headerName: "Status"},
                {field: "match_score", headerName: "Score", suppressSizeToFit: "false", hide: 'true'}
            ]
        };

       new agGrid.Grid($("#taxonomy_search_results").get(0), gridOptions);

        getResultData();

        newSearch = false;
    }

    function getResultData(){

        // load the parameters from the form to add to the query string sent in the ajax data call

        var search_type = $("#taxonomy_search_type");
        var page_size = $("#taxonomy_search_page_size");

        var searchParams = "?taxonomy_search_text=" + $("#taxonomy_search_text").val() + "&taxonomy_search_page_size=" + page_size.val()
            + "&taxonomy_search_type=" + search_type.val() + "&new_search=" + newSearch;

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

        // set the grid datasource options, including processing the data rows
        var dataSource = {

            paginationPageSize: pageSize,
            getRows: function (params) {

                var pageNumber = params.endRow / pageSize;

                searchParams += "&taxonomy_search_page_number=" + pageNumber;

                // make an ajax call to get the data
                $.get( gon.routes.search_get_search_results_path + searchParams, function( search_results ) {

                    if (search_results.data.length > 0){
                        $("#taxonomy_search_export").show();
                    } else {
                        $("#taxonomy_search_export").hide();
                    }
                    params.successCallback(search_results.data, search_results.total_number);
                });
            }
        };

        gridOptions.api.setDatasource(dataSource);

        // reload the recents menu
        //loadAssemblageRecents();
        UIHelper.loadAutoSuggestRecents("taxonomy_search_assemblage_recents", null);
    }

    function onGridSelection(){

        var selectedRows = gridOptions.api.getSelectedRows();

        selectedRows.forEach( function(selectedRow, index) {

            console.log('Row with ID ' + selectedRow.id + ' ' + selectedRow.concept_status + '.');
            $.publish(KometChannels.Taxonomy.taxonomySearchResultSelectedChannel, [selectedRow.id, WindowManager.getLinkedViewerID()]);
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

    function loadExportGrid() {

        // If a grid already exists destroy it or it will create a second grid
        if (gridOptions_Exprot){
            gridOptions_Exprot.api.destroy();
        }
        gridOptions_Exprot = {
             rowModelType: 'pagination',
             columnDefs:  [
                {field: "id", headerName: 'ID', hide: 'true'},
                {field: "matching_concept", headerName: "Matching Concept", cellRenderer: function(params) {
                    return '<span class="komet-context-menu" data-menu-type="concept" data-menu-uuid="' + params.data.id + '" '
                        + 'data-menu-state="' + params.data.concept_status + '" data-menu-concept-text="' + params.data.matching_concept + '">' + params.value + '</span>';
                }},
                {field: "matching_terms", headerName: "Matching Terms"},
                {field: "concept_status", headerName: "Status"},
                {field: "match_score", headerName: "Score", suppressSizeToFit: "false", hide: 'true'}
            ]
        };

        new agGrid.Grid($("#taxonomy_search_exportresults").get(0), gridOptions_Exprot);
        $("#taxonomy_search_exportresults").hide();
        // load the parameters from the form to add to the query string sent in the ajax data call
        newSearch = true;
        var search_type = $("#taxonomy_search_type");
        var page_size =10000000;

        var searchParams = "?taxonomy_search_text=" + $("#taxonomy_search_text").val() + "&taxonomy_search_page_size=" + page_size
            + "&taxonomy_search_type=" + search_type.val() + "&new_search=" + newSearch;

        // set only the parameters needed based on the search type
        if (search_type.val() === "descriptions"){
            searchParams += "&taxonomy_search_description_type=" + $("#taxonomy_search_description_type").val();
        } else if (search_type.val() === "sememes"){
            searchParams += "&taxonomy_search_treat_as_string=" + $("#taxonomy_search_treat_as_string").val() + "&taxonomy_search_assemblage_id=" + $("#taxonomy_search_assemblage").val()
                + "&taxonomy_search_assemblage_display=" + $("#taxonomy_search_assemblage_display").val();
        } else {
            searchParams += "&taxonomy_search_id_type=" + $("#taxonomy_search_id_type").val()
        }

        var pageSize = Number(page_size);

        // set the grid datasource options, including processing the data rows
        var dataSource2 = {

            paginationPageSize: pageSize,
            getRows: function (params) {

                var pageNumber = 1;

                searchParams += "&taxonomy_search_page_number=" + pageNumber;
                console.log(searchParams);
                // make an ajax call to get the data
                $.get( gon.routes.search_get_search_results_path + searchParams, function( search_results ) {
                    params.successCallback(search_results.data, search_results.total_number);
                });
            }
        };

        gridOptions_Exprot.api.setDatasource(dataSource2);

    }
    function exportCSV(){
       // TaxonomySearchModule.loadExportGrid();
        gridOptions_Exprot.api.exportDataAsCsv({allColumns: true});
    }

    return {
        initialize: init,
        loadResultGrid: loadResultGrid,
        changeSearchType: changeSearchType,
        exportCSV: exportCSV,
        loadExportGrid:loadExportGrid
    };

})();