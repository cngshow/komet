var MappingModule = (function () {


    var deferred;
    const SET_LIST = 'komet_dashboard/mapping/map_set_list';
    const SET_DETAILS = 'komet_dashboard/mapping/map_set_details';
    const SET_EDITOR = 'komet_dashboard/mapping/map_set_editor';
    const ITEM_EDITOR = 'komet_dashboard/mapping/map_item_editor';

    function init() {

        subscribeToMappingTree();

        this.tree = new KometMappingTree("komet_mapping_tree", WindowManager.NEW);

        /*
        showOverviewSTAMP = false;
        showOverviewInactiveConcepts = false;

        loadOverviewSetsGrid();

        */

    }

    function subscribeToMappingTree() {

        // listen for the onChange event broadcast by any of the taxonomy this.trees.
        $.subscribe(KometChannels.Mapping.mappingTreeNodeSelectedChannel, function (e, treeID, setID, viewerID, windowType) {

            if (WindowManager.viewers.inlineViewers.length == WindowManager.viewers.maxInlineViewers){

                windowType = WindowManager.INLINE;
                viewerID = WindowManager.getLinkedViewerID();
            }

            if (deferred && deferred.state() == "pending"){
                deferred.done(function(){
                    MappingModule.loadViewerData(setID, "set_list", WindowManager.getLinkedViewerID(), windowType)
                }.bind(this));
            } else {
                MappingModule.loadViewerData(setID, "set_list", viewerID, windowType);
            }
        });
    }

    // the path to a javascript partial file that will re-render all the appropriate partials once the ajax call returns
    function loadViewerData(id, mapping_action, viewerID, windowType) {

        deferred = $.Deferred();

        var params = {partial: 'komet_dashboard/mapping/mapping_viewer', mapping_action: mapping_action, viewer_id: viewerID};
        var url = gon.routes.mapping_load_mapping_viewer_path;

        if (mapping_action == "set_list"){
            params.set_id = id;
        }


        // make an ajax call to get the concept for the current concept and pass it the currently selected concept id and the name of a partial file to render
        $.get(url, params, function (data) {

            try {

                WindowManager.loadViewerData(data, viewerID, "mapping", windowType);

                if (windowType != WindowManager.NEW && windowType != WindowManager.POPUP) {
                    deferred.resolve();
                }
            }
            catch (err) {
                console.log("*******  ERROR **********");
                console.log(err.message);
                throw err;
            }

        });
    }

    function createViewer(viewerID, setID) {

        WindowManager.createViewer(new MappingViewer(viewerID, setID));
        deferred.resolve();
    }



    function exportOverviewSetsCSV() {
        overviewSetsGridOptions.api.exportDataAsCsv({allColumns: true});
    }

    function loadOverviewItemsGrid(set_id) {

        // If a grid already exists destroy it or it will create a second grid
        if (overviewItemsGridOptions) {
            overviewItemsGridOptions.api.destroy();
        }

        // disable item specific actions
        UIHelper.toggleFieldAvailability("komet_mapping_overview_item_delete", false);
        UIHelper.toggleFieldAvailability("komet_mapping_overview_item_edit", false);
        UIHelper.toggleFieldAvailability("komet_mapping_overview_item_comment", false);

        // set the options for the result grid
        overviewItemsGridOptions = {
            enableColResize: true,
            enableSorting: true,
            suppressCellSelection: true,
            rowSelection: "single",
            onSelectionChanged: onOverviewItemsGridSelection,
            onGridReady: onGridReady,
            rowModelType: 'pagination',
            columnDefs: [
                {field: "id", headerName: "id", hide: "true"},
                {field: "source", headerName: 'Source ID', hide: "true"},
                {field: "source_display", headerName: "Source Concept"},
                {field: "target", headerName: "Target ID", hide: "true"},
                {field: "target_display", headerName: "Target Concept"},
                {field: "qualifier", headerName: "Qualifier"},
                {field: "comments", headerName: "Comments"},
                {field: "review_state", headerName: "Review State"},
                {
                    groupId: "stamp", headerName: "STAMP Fields", children: [
                    {field: "status", headerName: "Status", hide: !showOverviewSTAMP},
                    {field: "time", headerName: "Time", hide: !showOverviewSTAMP},
                    {field: "author", headerName: "Author", hide: !showOverviewSTAMP},
                    {field: "module", headerName: "Module", hide: !showOverviewSTAMP},
                    {field: "path", headerName: "Path", hide: !showOverviewSTAMP}
                ]
                }
            ]
        };

        new agGrid.Grid($("#komet_mapping_overview_items").get(0), overviewItemsGridOptions);

        if (set_id == undefined) {
            overviewItemsGridOptions.api.showNoRowsOverlay()
        } else {
            getOverviewItemsData(set_id);
        }
    }

    function getOverviewItemsData(set_id) {

        // load the parameters from the form to add to the query string sent in the ajax data call
        var page_size = $("#komet_mapping_overview_page_size").val();
        var filter = $("#komet_mapping_overview_items_filter").val();

        var searchParams = "?overview_set_id=" + set_id + "&overview_page_size=" + page_size + "&show_inactive=" + showOverviewInactiveConcepts;

        if (filter != null) {
            searchParams += "overview_items_filter=" + filter;
        }

        var pageSize = Number(page_size);

        // set the grid datasource options, including processing the data rows
        var dataSource = {

            pageSize: pageSize,
            getRows: function (params) {

                var pageNumber = params.endRow / pageSize;

                searchParams += "&overview_items_page_number=" + pageNumber;

                // make an ajax call to get the data
                $.get(gon.routes.mapping_get_overview_items_results_path + searchParams, function (search_results) {

                    if (search_results.data.length > 0) {
                        $("#komet_mapping_overview_items_export").show();
                    } else {
                        $("#komet_mapping_overview_items_export").hide();
                    }
                    params.successCallback(search_results.data, search_results.total_number);
                });
            }
        };

        overviewItemsGridOptions.api.setDatasource(dataSource);

        // reload the recents menu
        //loadAssemblageRecents();
    }

    function onOverviewItemsGridSelection() {

        // enable item specific actions
        UIHelper.toggleFieldAvailability("komet_mapping_overview_item_delete", true);
        UIHelper.toggleFieldAvailability("komet_mapping_overview_item_edit", true);
        UIHelper.toggleFieldAvailability("komet_mapping_overview_item_comment", true);

        var selectedRows = overviewItemsGridOptions.api.getSelectedRows();

        //selectedRows.forEach(function (selectedRow, index) {});
    }

    function openSetEditor(newSet) {

        var url = gon.routes.mapping_map_set_editor_path;

        if (!newSet) {
            url += "?set_id=" + overviewSetsGridOptions.api.getSelectedRows()[0].id;
        }

        setEditorWindow = window.open(url, "MapSetEditor", "width=600,height=330");
    }

    function initializeSetEditor() {

        $("#komet_mapping_set_editor_form").submit(function () {

            $.ajax({
                type: "POST",
                url: $(this).attr("action"),
                data: $(this).serialize(), //new FormData($(this)[0]),
                success: function () {

                    window.opener.MappingModule.loadOverviewSetsGrid();
                    window.close();
                }
            });

            // have to return false to stop the form from posting twice.
            return false;
        });
    }

    function openItemEditor(newItem) {

        var url = gon.routes.mapping_map_item_editor_path + "?set_id=" + overviewSetsGridOptions.api.getSelectedRows()[0].id;

        if (!newItem) {
            url += "&item_id=" + overviewItemsGridOptions.api.getSelectedRows()[0].id;
        }

        itemEditorWindow = window.open(url, "MapItemEditor", "width=1010,height=680");
    }

    function initializeItemEditor() {

        // setup the source field autocomplete functionality
        $("#komet_mapping_item_editor_source_display").autocomplete({
            source: gon.routes.mapping_get_item_source_suggestions_path,
            minLength: 3,
            select: onItemSourceSuggestionSelection,
            change: onItemSourceSuggestionChange
        });

        loadItemSourceRecents();

        // setup the target field autocomplete functionality
        $("#komet_mapping_item_editor_target_display").autocomplete({
            source: gon.routes.mapping_get_item_target_suggestions_path,
            minLength: 3,
            select: onItemTargetSuggestionSelection,
            change: onItemTargetSuggestionChange
        });

        loadItemTargetRecents();

        // setup the Kind Of field autocomplete functionality
        $("#komet_mapping_item_editor_kind_of_display").autocomplete({
            source: gon.routes.mapping_get_item_kind_of_suggestions_path,
            minLength: 3,
            select: onItemKindOfSuggestionSelection,
            change: onItemKindOfSuggestionChange
        });

        loadItemKindOfRecents();

        // set the form to post the data to the controller and upon success reload the Items grid and close the window.
        $("#komet_mapping_item_editor_form").submit(function () {

            $.ajax({
                type: "POST",
                url: $(this).attr("action"),
                data: $(this).serialize(), //new FormData($(this)[0]),
                success: function () {

                    window.opener.MappingModule.loadOverviewItemsGrid($("#komet_mapping_item_editor_set_id").val());
                    window.close();
                }
            });

            // have to return false to stop the form from posting twice.
            return false;
        });

        loadTargetCandidatesGrid();
    }

    function onItemSourceSuggestionSelection(event, ui) {

        $("#komet_mapping_item_editor_source_display").val(ui.item.label);
        $("#komet_mapping_item_editor_source").val(ui.item.value);
        return false;
    }

    function onItemSourceSuggestionChange(event, ui) {

        if (!ui.item) {
            event.target.value = "";
            $("#komet_mapping_item_editor_source").val("");
        }
    }

    function loadItemSourceRecents() {

        $.get(gon.routes.mapping_get_item_source_recents_path, function (data) {

            var options = "";

            $.each(data, function (index, value) {

                // use the html function to escape any html that may have been entered by the user
                var valueText = $("<li>").text(value.text).html();
                options += "<li><a href=\"#\" onclick=\"MappingModule.useItemSourceRecent('" + value.id + "', '" + valueText + "')\">" + valueText + "</a></li>";
            });

            $("#komet_mapping_item_editor_source_recents").html(options);
        });
    }

    function useItemSourceRecent(id, text) {

        $("#komet_mapping_item_editor_source_display").val(text);
        $("#komet_mapping_item_editor_source").val(id);
    }

    function onItemTargetSuggestionSelection(event, ui) {

        $("#komet_mapping_item_editor_target_display").val(ui.item.label);
        $("#komet_mapping_item_editor_target").val(ui.item.value);
        return false;
    }

    function onItemTargetSuggestionChange(event, ui) {

        if (!ui.item) {
            event.target.value = "";
            $("#komet_mapping_item_editor_target").val("");
        }
    }

    function loadItemTargetRecents() {

        $.get(gon.routes.mapping_get_item_target_recents_path, function (data) {

            var options = "";

            $.each(data, function (index, value) {

                // use the html function to escape any html that may have been entered by the user
                var valueText = $("<li>").text(value.text).html();
                options += "<li><a href=\"#\" onclick=\"MappingModule.useItemTargetRecent('" + value.id + "', '" + valueText + "')\">" + valueText + "</a></li>";
            });

            $("#komet_mapping_item_editor_target_recents").html(options);
        });
    }

    function useItemTargetRecent(id, text) {

        $("#komet_mapping_item_editor_target_display").val(text);
        $("#komet_mapping_item_editor_target").val(id);
    }

    function onItemKindOfSuggestionSelection(event, ui) {

        $("#komet_mapping_item_editor_kind_of_display").val(ui.item.label);
        $("#komet_mapping_item_editor_kind_of").val(ui.item.value);
        return false;
    }

    function onItemKindOfSuggestionChange(event, ui) {

        if (!ui.item) {
            event.target.value = "";
            $("#komet_mapping_item_editor_kind_of").val("");
        }
    }

    function loadItemKindOfRecents() {

        $.get(gon.routes.mapping_get_item_kind_of_recents_path, function (data) {

            var options = "";

            $.each(data, function (index, value) {

                // use the html function to escape any html that may have been entered by the user
                var valueText = $("<li>").text(value.text).html();
                options += "<li><a href=\"#\" onclick=\"MappingModule.useItemKindOfRecent('" + value.id + "', '" + valueText + "')\">" + valueText + "</a></li>";
            });

            $("#komet_mapping_item_editor_kind_of_recents").html(options);
        });
    }

    function useItemKindOfRecent(id, text) {

        $("#komet_mapping_item_editor_kind_of_display").val(text);
        $("#komet_mapping_item_editor_kind_of").val(id);
    }

    function loadTargetCandidatesGrid(showData) {

        // If a grid already exists destroy it or it will create a second grid
        if (targetCandidatesGridOptions) {
            targetCandidatesGridOptions.api.destroy();
        }

        // set the options for the result grid
        targetCandidatesGridOptions = {
            enableColResize: true,
            enableSorting: true,
            suppressCellSelection: true,
            rowSelection: "single",
            onSelectionChanged: onTargetCandidatesGridSelection,
            onGridReady: onGridReady,
            rowModelType: 'pagination',
            columnDefs: [
                {field: "id", headerName: "id", hide: "true"},
                {field: "concept", headerName: "Concept"},
                {field: "code_system", headerName: "Code System"},
                {field: "status", headerName: "Status"}
            ]
        };

        new agGrid.Grid($("#komet_mapping_item_editor_target_candidates").get(0), targetCandidatesGridOptions);

        if (showData == undefined) {
            targetCandidatesGridOptions.api.showNoRowsOverlay()
        } else {
            getTargetCandidatesData();
        }
    }

    function getTargetCandidatesData() {

        $("#komet_taxonomy_search_form").find(".komet-form-error").remove();

        var search_text = $("#komet_mapping_item_editor_target_candidates_search").val();

        if (search_text === ""){

            $("#komet_mapping_item_editor_target_candidates_search_section").after(UIHelper.generateFormErrorMessage("Candidate Criteria cannot be blank."));
            return;
        }

        // load the parameters from the form to add to the query string sent in the ajax data call
        var page_size = $("#komet_mapping_item_editor_target_candidates_page_size").val();
        var description_type = $("#komet_mapping_item_editor_description_type").val();
        var advanced_description_type = $("#komet_mapping_item_editor_advanced_description_type").val();
        var code_system = $("#komet_mapping_item_editor_code_system").val();
        var assemblage = $("#komet_mapping_item_editor_assemblage").val();
        var kind_of = $("#komet_mapping_item_editor_kind_of").val();

        var searchParams = "?search_text=" + search_text + "&page_size=" + page_size + "&description_type=" + description_type
            + "&advanced_description_type=" + advanced_description_type + "&code_system=" + code_system + "&assemblage=" + assemblage + "&kind_of=" + kind_of;

        var pageSize = Number(page_size);

        // set the grid datasource options, including processing the data rows
        var dataSource = {

            pageSize: pageSize,
            getRows: function (params) {

                var pageNumber = params.endRow / pageSize;

                searchParams += "&page_number=" + pageNumber;

                // make an ajax call to get the data
                $.get(gon.routes.mapping_get_target_candidates_results_path + searchParams, function (search_results) {

                    params.successCallback(search_results.data, search_results.total_number);
                });
            }
        };

        targetCandidatesGridOptions.api.setDatasource(dataSource);
    }

    function onTargetCandidatesGridSelection() {

        var selectedRows = targetCandidatesGridOptions.api.getSelectedRows();

        selectedRows.forEach(function (selectedRow, index) {

            $("#komet_mapping_item_editor_target").val(selectedRow.id);
            $("#komet_mapping_item_editor_target_display").val(selectedRow.concept);
        });
    }

    return {
        initialize: init,
        loadViewerData: loadViewerData,
        createViewer: createViewer,
        loadOverviewItemsGrid: loadOverviewItemsGrid,
        exportOverviewSetsCSV: exportOverviewSetsCSV,
        openSetEditor: openSetEditor,
        initializeSetEditor: initializeSetEditor,
        openItemEditor: openItemEditor,
        initializeItemEditor: initializeItemEditor,
        useItemSourceRecent: useItemSourceRecent,
        useItemTargetRecent: useItemTargetRecent,
        useItemKindOfRecent: useItemKindOfRecent,
        loadTargetCandidatesGrid: loadTargetCandidatesGrid,
        SET_LIST: SET_LIST,
        SET_DETAILS: SET_DETAILS,
        SET_EDITOR: SET_EDITOR,
        ITEM_EDITOR: ITEM_EDITOR
    };

})();