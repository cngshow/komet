/**
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
    
var MappingViewer = function(viewerID, currentSetID) {

    MappingViewer.prototype.init = function(viewerID, currentSetID) {

        this.viewerID = viewerID;
        this.currentSetID = currentSetID;
        this.panelStates = {};
        this.overviewSetsGridOptions = null;
        this.overviewItemsGridOptions = null;
        this.targetCandidatesGridOptions = null;
        this.showOverviewInactiveConcepts = null;
        this.showOverviewSTAMP = null;
        this.setEditorWindow = null;
        this.itemEditorWindow = null;
    };

    MappingViewer.prototype.togglePanelDetails = function(panelID, callback, preserveState) {

        // get the panel's expander icon, or all expander icons if this is the top level expander
        var expander = $("#" + panelID + " .glyphicon-plus-sign, #" + panelID + " .glyphicon-minus-sign");
        var drawer = $("#" + panelID + " .komet-mapping-section-panel-details");
        var open = expander.hasClass("glyphicon-plus-sign");
        
        // change the displayed expander icon and drawer visibility
        if (open) {

            expander.removeClass("glyphicon-plus-sign");
            expander.addClass("glyphicon-minus-sign");
            drawer.show();

        } else {

            expander.removeClass("glyphicon-minus-sign");
            expander.addClass("glyphicon-plus-sign");
            drawer.hide();
        }

        // save state if needed, and if there is a callback run it, passing the panel ID, open state, and set ID.

        if (preserveState) {
            this.setPanelState(panelID, open, callback);
        }

        // run the callback
        if (this.panelStates[panelID] !== undefined && this.panelStates[panelID].length > 1 && this.panelStates[panelID][1]) {
            this.panelStates[panelID][1](panelID, open, this.currentSetID);
        }
    };

    MappingViewer.prototype.setPanelState = function(panelID, state, callback) {

        if (this.panelStates[panelID] === undefined) {
            this.panelStates[panelID] = [];
        }

        if (state !== null) {
            this.panelStates[panelID][0] = state;
        }

        if (callback){
            this.panelStates[panelID][1] = callback;
        }
    };

    MappingViewer.prototype.getPanelState = function(panelID) {

        if(!this.panelStates[panelID]) {
            return false;
        }

        return this.panelStates[panelID][0];
    };

    MappingViewer.prototype.restorePanelStates = function() {

        for (var key in this.panelStates) {

            var state = this.panelStates[key][0];
            var callback = this.panelStates[key][1];

            if (state) {
                this.togglePanelDetails(key, callback);
            }
        }
    };

    // show this map set in the mapping tree
    MappingViewer.prototype.showInMappingTree = function() {

        MappingModule.tree.findNodeInTree(
            this.currentSetID,
            function (foundNodeId) {},
            true
        );
    };

    MappingViewer.prototype.swapLinkIcon = function(linked){

        var linkIcon = $('#komet_mapping_panel_tree_link_' + this.viewerID);

        linkIcon.toggleClass("fa-chain", linked);
        linkIcon.toggleClass("fa-chain-broken", !linked);
        this.toggleTreeIcon();
    };

    MappingViewer.prototype.toggleTreeIcon = function(){
        $('#komet_mapping_panel_tree_show_' + this.viewerID).toggle();
    };

    MappingViewer.prototype.loadOverviewSetsGrid = function(){

        // If a grid already exists destroy it or it will create a second grid
        if (this.overviewSetsGridOptions) {
            this.overviewSetsGridOptions.api.destroy();
        }

        if (this.overviewItemsGridOptions) {

            this.overviewItemsGridOptions.api.destroy();
            this.overviewItemsGridOptions = undefined;
        }

        // disable map set and item specific actions
        UIHelper.toggleFieldAvailability("komet_mapping_overview_set_delete_" + this.viewerID, false);
        UIHelper.toggleFieldAvailability("komet_mapping_overview_set_edit_" + this.viewerID, false);
        //UIHelper.toggleFieldAvailability("komet_mapping_overview_item_create_" + this.viewerID, false);
        //UIHelper.toggleFieldAvailability("komet_mapping_overview_item_delete_" + this.viewerID, false);
        //UIHelper.toggleFieldAvailability("komet_mapping_overview_item_edit_" + this.viewerID, false);
        //UIHelper.toggleFieldAvailability("komet_mapping_overview_item_comment_" + this.viewerID, false);

        // set the options for the result grid
        this.overviewSetsGridOptions = {
            enableColResize: true,
            enableSorting: true,
            suppressCellSelection: true,
            rowSelection: "single",
            onSelectionChanged: this.onOverviewSetsGridSelection,
            onGridReady: this.onGridReady,
            rowModelType: 'pagination',
            columnDefs: [
                {field: "id", headerName: 'id', hide: 'true'},
                {field: "name", headerName: 'Name'},
                {field: "purpose", headerName: 'Purpose'},
                {field: "description", headerName: "Description"},
                {field: "review_state", headerName: "Review State"},
                {
                    groupId: "stamp", headerName: "STAMP Fields", children: [
                    {field: "status", headerName: "Status", hide: !this.showOverviewSTAMP},
                    {field: "time", headerName: "Time", hide: !this.showOverviewSTAMP},
                    {field: "author", headerName: "Author", hide: !this.showOverviewSTAMP},
                    {field: "module", headerName: "Module", hide: !this.showOverviewSTAMP},
                    {field: "path", headerName: "Path", hide: !this.showOverviewSTAMP}
                ]
                }
            ]
        };

        new agGrid.Grid($("#komet_mapping_overview_sets_" + this.viewerID).get(0), this.overviewSetsGridOptions);

        this.getOverviewSetsData();
    };

    MappingViewer.prototype.getOverviewSetsData = function(){

        // load the parameters from the form to add to the query string sent in the ajax data call
        var page_size = $("#komet_mapping_overview_page_size_" + this.viewerID).val();
        var filter = $("#komet_mapping_overview_sets_filter_" + this.viewerID).val();

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

                searchParams += "&overview_sets_page_number=" + pageNumber + "&show_inactive=" + this.showOverviewInactiveConcepts;

                // make an ajax call to get the data
                $.get(gon.routes.mapping_get_overview_sets_results_path + searchParams, function (search_results) {
                    params.successCallback(search_results.data, search_results.total_number);
                }.bind(this));
            }.bind(this)
        };

        this.overviewSetsGridOptions.api.setDatasource(dataSource);
    };

    MappingViewer.prototype.onOverviewSetsGridSelection = function(){

        // enable map set specific actions
        UIHelper.toggleFieldAvailability("komet_mapping_overview_set_delete_" + this.viewerID, true);
        UIHelper.toggleFieldAvailability("komet_mapping_overview_set_edit_" + this.viewerID, true);
        UIHelper.toggleFieldAvailability("komet_mapping_overview_item_create_" + this.viewerID, true);

        var selectedRows = this.overviewSetsGridOptions.api.getSelectedRows();

        selectedRows.forEach(function (selectedRow, index) {

            //loadOverviewItemsGrid(selectedRow.id);
        });
    }.bind(this);

    MappingViewer.prototype.onGridReady = function(event){
        event.api.sizeColumnsToFit();
    };

    MappingViewer.prototype.toggleOverviewSTAMP = function(){

        if (this.overviewItemsGridOptions) {

            if (this.showOverviewSTAMP) {
                this.overviewItemsGridOptions.columnApi.setColumnsVisible(["status", "time", "author", "module", "path"], false);
            } else {
                this.overviewItemsGridOptions.columnApi.setColumnsVisible(["status", "time", "author", "module", "path"], true);
            }

            this.overviewItemsGridOptions.api.sizeColumnsToFit();
        }

        if (this.showOverviewSTAMP) {

            this.showOverviewSTAMP = false;
            $("#komet_mapping_overview_sets_stamp_" + this.viewerID).removeClass("komet-active-control");
            this.overviewSetsGridOptions.columnApi.setColumnsVisible(["status", "time", "author", "module", "path"], false);
        } else {

            this.showOverviewSTAMP = true;
            $("#komet_mapping_overview_sets_stamp_" + this.viewerID).addClass("komet-active-control");
            this.overviewSetsGridOptions.columnApi.setColumnsVisible(["status", "time", "author", "module", "path"], true);
        }

        this.overviewSetsGridOptions.api.sizeColumnsToFit();
    };

    MappingViewer.prototype.toggleOverviewInactiveConcepts = function(){

        if (this.showOverviewInactiveConcepts){

            this.showOverviewInactiveConcepts = false
            $("#komet_mapping_overview_sets_inactive_" + this.viewerID).removeClass("komet-active-control");
        } else {

            this.showOverviewInactiveConcepts = true
            $("#komet_mapping_overview_sets_inactive_" + this.viewerID).addClass("komet-active-control");
        }

        this.loadOverviewSetsGrid();
    };

    // call our constructor function
    this.init(viewerID, currentSetID)
};
