var TaxonomySearchModule = (function () {

    var newSearch = true;
    var gridOptions;

    function init() {

        // setup the advanced search options accordion
        $("#taxonomy_search_options_pane").accordion({
            collapsible: true,
            active: true,
            heightStyle: "content",
            animate: false
        });

        // setup the assemblage field autocomplete functionality
        $("#taxonomy_search_assemblage_display").autocomplete({
            source: gon.routes.search_get_assemblage_suggestions_path,
            minLength: 3,
            select: onAssemblageSuggestionSelection,
            change: onAssemblageSuggestionChange
        });

        // load any previous assemblage queries into a menu for the user to select from
        //loadAssemblageRecents();
    }

    function loadResultGrid() {

        $("#komet_taxonomy_search_form").find(".komet-form-error").remove();

        if ($("#taxonomy_search_text").val() === ""){

            $("#taxonomy_search_combo_field").after(UIHelper.generateFormErrorMessage("Search Text cannot be blank."));
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
            suppressCellSelection: true,
            rowSelection: "single",
            onSelectionChanged: onGridSelection,
            onGridReady: onGridReady,
            rowModelType: 'pagination',
            columnDefs:  [
                {field: "id", headerName: 'ID', hide: 'true'},
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
        }
        else {
            searchParams += "&taxonomy_search_treat_as_string=" + $("#taxonomy_search_treat_as_string").val() + "&taxonomy_search_assemblage_id=" + $("#taxonomy_search_assemblage_id").val()
                + "&taxonomy_search_assemblage_display=" + $("#taxonomy_search_assemblage_display").val();
        }

        var pageSize = Number(page_size.val());

        // set the grid datasource options, including processing the data rows
        var dataSource = {

            pageSize: pageSize,
            getRows: function (params) {

                var pageNumber = params.endRow / pageSize;

                searchParams += "&taxonomy_search_page_number=" + pageNumber;

                // make an ajax call to get the data
                $.get( gon.routes.search_get_search_results_path + searchParams, function( search_results ) {
                    params.successCallback(search_results.data, search_results.total_number);
                });
            }
        };

        gridOptions.api.setDatasource(dataSource);

        // reload the recents menu
        loadAssemblageRecents();
    }

    function onGridSelection(){

        var selectedRows = gridOptions.api.getSelectedRows();

        selectedRows.forEach( function(selectedRow, index) {

            console.log('Row with ID ' + selectedRow.id + ' ' + selectedRow.concept_status + '.');
            $.publish(KometChannels.Taxonomy.taxonomySearchResultSelectedChannel, [selectedRow.id, TaxonomyModule.getLinkedViewerID()]);
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

        $("#taxonomy_search_option_description_type_fields").toggle();
        $("#taxonomy_search_sememe_fields").toggle();
    }

    function onAssemblageSuggestionSelection(event, ui){

        $("#taxonomy_search_assemblage_display").val(ui.item.label);
        $("#taxonomy_search_assemblage_id").val(ui.item.value);
        return false;
    }

    function onAssemblageSuggestionChange(event, ui){

        if (!ui.item){
            event.target.value = "";
            $("#taxonomy_search_assemblage_id").val("");
        }
    }

    function loadAssemblageRecents() {

        $.get(gon.routes.search_get_assemblage_recents_path, function (data) {

            var options = "";

            $.each(data, function (index, value) {

                // use the html function to escape any html that may have been entered by the user
                var valueText = $("<li>").text(value.text).html();
                options += "<li><a href=\"#\" onclick=\"useAssemblageRecent('" + value.id + "', '" + valueText + "')\">" + valueText + "</a></li>";
            });

            $("#taxonomy_search_assemblage_recents").html(options);
        });
    }

    function useAssemblageRecent(id, text){

        $("#taxonomy_search_assemblage_display").val(text);
        $("#taxonomy_search_assemblage_id").val(id);
    }

    return {
        initialize: init,
        loadResultGrid: loadResultGrid,
        changeSearchType: changeSearchType
    };

})();