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
    
var MappingViewer = function(viewerID, currentSetID, mappingAction) {

    MappingViewer.prototype.init = function(viewerID, currentSetID, mappingAction) {

        this.viewerID = viewerID;
        this.currentSetID = currentSetID;
        this.panelStates = {};
        this.overviewSetsGridOptions = null;
        this.overviewItemsGridOptions = null;
        this.targetCandidatesGridOptions = null;
        this.showOverviewInactiveConcepts = null;
        this.showSetsSTAMP = false;
        this.showItemsSTAMP = false;
        this.itemEditorWindow = null;
        this.mappingAction = mappingAction;
        this.setEditorCreatedFields = [];
        this.setEditorMapSet = {};
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

        // disable map set and item specific actions
        UIHelper.toggleFieldAvailability("komet_mapping_overview_set_delete_" + this.viewerID, false);
        UIHelper.toggleFieldAvailability("komet_mapping_overview_set_edit_" + this.viewerID, false);

        // set the options for the result grid
        this.overviewSetsGridOptions = {
            enableColResize: true,
            enableSorting: true,
            suppressCellSelection: true,
            rowSelection: "single",
            onSelectionChanged: this.onOverviewSetsGridSelection,
            onRowDoubleClicked: this.onOverviewSetsGridDoubleClick,
            onGridReady: this.onGridReady,
            rowModelType: 'pagination',
            columnDefs: [
                {field: "set_id", headerName: 'ID', hide: 'true'},
                {field: "name", headerName: 'Name'},
                {field: "description", headerName: "Description"},
                {
                    groupId: "stamp", headerName: "STAMP Fields", children: [
                    {field: "state", headerName: "State", hide: !this.showSetsSTAMP},
                    {field: "time", headerName: "Time", hide: !this.showSetsSTAMP},
                    {field: "author", headerName: "Author", hide: !this.showSetsSTAMP},
                    {field: "module", headerName: "Module", hide: !this.showSetsSTAMP},
                    {field: "path", headerName: "Path", hide: !this.showSetsSTAMP}
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

        var selectedRows = this.overviewSetsGridOptions.api.getSelectedRows();

        selectedRows.forEach(function (selectedRow, index) {

            //loadOverviewItemsGrid(selectedRow.id);
        });
    }.bind(this);

    MappingViewer.prototype.onOverviewSetsGridDoubleClick = function(){

        var selectedRows = this.overviewSetsGridOptions.api.getSelectedRows();

        selectedRows.forEach(function (selectedRow, index) {
            $.publish(KometChannels.Mapping.mappingTreeNodeSelectedChannel, [null, selectedRow.set_id, this.viewerID, WindowManager.INLINE]);
        });
    }.bind(this);

    MappingViewer.prototype.onGridReady = function(event){
        event.api.sizeColumnsToFit();
    };

    MappingViewer.prototype.toggleOverviewSTAMP = function(){

        if (this.showSetsSTAMP) {

            this.showSetsSTAMP = false;
            $("#komet_mapping_overview_sets_stamp_" + this.viewerID).removeClass("komet-active-control");
            this.overviewSetsGridOptions.columnApi.setColumnsVisible(["state", "time", "author", "module", "path"], false);
        } else {

            this.showSetsSTAMP = true;
            $("#komet_mapping_overview_sets_stamp_" + this.viewerID).addClass("komet-active-control");
            this.overviewSetsGridOptions.columnApi.setColumnsVisible(["state", "time", "author", "module", "path"], true);
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

    MappingViewer.prototype.initializeSetEditor = function(mappingAction){

        var form = $("#komet_mapping_set_editor_form_" + this.viewerID);

        this.mappingAction = mappingAction;
        this.setEditorCreatedFields = [];

        var includeFields = "";

        for (var i = 0; i < this.setEditorMapSet["include_fields"].length; i++){

            var fieldName = this.setEditorMapSet["include_fields"][i];
            var fieldInfo = this.setEditorMapSet[fieldName];

            includeFields += '<div class="komet-mapping-set-added-' + fieldName + '">'
                + '<input type="checkbox" name="komet_mapping_set_editor_include_fields[]" class="form-control" '
                + 'id="komet_mapping_set_editor_include_fields_' + fieldName + '_' + this.viewerID + '" value="' + fieldName + '" ';

            if (fieldInfo.display){
                includeFields += 'checked="checked"';
            }

            includeFields += '><label for="komet_mapping_set_editor_include_fields_' + fieldName + '_' + this.viewerID + '">' + fieldInfo.label + '</label></div>';
        }

        // create a dom fragment from our included fields structure and append it to the dialog form
        $("#komet_mapping_dialog_include_fields_" + this.viewerID).append(document.createRange().createContextualFragment(includeFields));

        this.generateSetEditorAdditionalFields();

        if (mappingAction == MappingModule.SET_DETAILS){
            form.find(".komet-mapping-set-editor-edit").hide();

            if (this.currentSetID != null && this.currentSetID != ""){
                this.loadOverviewItemsGrid();

                UIHelper.toggleFieldAvailability("komet_mapping_overview_item_create_" + this.viewerID, true);
            }
        } else {
            form.find(".komet-mapping-set-editor-display").hide();
        }

        $("#komet_mapping_set_tabs_" + this.viewerID).tabs();

        var thisViewer = this;

        form.submit(function () {

            $.ajax({
                type: "POST",
                url: $(this).attr("action"),
                data: $(this).serialize(), //new FormData($(this)[0]),
                success: function (data) {

                    MappingModule.tree.reloadTree();
                    MappingModule.callLoadViewerData(data.set_id, MappingModule.SET_DETAILS, thisViewer.viewerID);
                }
            });

            // have to return false to stop the form from posting twice.
            return false;
        });

    };

    MappingViewer.prototype.generateSetEditorAdditionalFields = function(){

        // remove all added fields from the form so we can start fresh
        var definitionTab = $("#komet_mapping_set_definition_tab_" + this.viewerID);
        definitionTab.find(".komet-mapping-set-added-row").remove();

        var includeCheckboxes = $("#komet_mapping_dialog_add_set_fields_" + this.viewerID).find("[name='komet_mapping_set_editor_include_fields[]']")

        var fieldsToInclude = $.map(includeCheckboxes.filter(":checked"), function(element) {
                return element.value;
        }.bind(this));

        var includedFields = "";
        var addedTag = "komet-mapping-set-added-"

        // build up the structure for displaying the included fields
        for (var i = 0; i < fieldsToInclude.length; i++){

            var even = (i % 2 === 0);

            if (even){
                includedFields += '<div class="komet-mapping-set-definition-row komet-mapping-set-added-row">';
            }

            includedFields += '<div class="komet-mapping-set-definition-item ' + addedTag + fieldsToInclude[i] + '">';

            var name = 'name="komet_mapping_set_editor_' + fieldsToInclude[i]+ ' ';
            var id = 'id="komet_mapping_set_editor_' + fieldsToInclude[i] + '_' + this.viewerID + ' ';
            var classes = "form-control komet-mapping-set-editor-edit";
            var value = "";
            var type = "text";
            var label = '<label for="' + fieldsToInclude[i] + '_' + this.viewerID + '">' + fieldsToInclude[i] + '</label>';

            if (this.setEditorMapSet[fieldsToInclude[i]] != undefined){

                value = this.setEditorMapSet[fieldsToInclude[i]].value;
                type = this.setEditorMapSet[fieldsToInclude[i]].type;
                label = '<label for="' + fieldsToInclude[i] + '_' + this.viewerID + '">' + this.setEditorMapSet[fieldsToInclude[i]].label + ':</label>';
            }

            if (fieldsToInclude[i] == "source_system"){

                var displayValue = "";

                if (this.setEditorMapSet[fieldsToInclude[i] + "_display"] != undefined){
                    displayValue = this.setEditorMapSet[fieldsToInclude[i] + "_display"];
                }

                includedFields += '<autosuggest '
                    + 'id-base="komet_mapping_set_editor_source_system" '
                    + 'id-postfix="_' + this.viewerID + '" '
                    + 'label="Source Code System:" '
                    + 'value="' + value + '" '
                    + 'display-value="' + displayValue + '" '
                    + 'classes="komet-mapping-set-editor-edit" '
                    + 'suggestion-rest-variable="mapping_get_item_target_suggestions_path" '
                    + 'recents-rest-variable="mapping_get_item_source_recents_path" '
                    + '></autosuggest>'
                
            } else if (fieldsToInclude[i] == "target_system"){

                var display_value = "";

                if (this.setEditorMapSet[fieldsToInclude[i] + "_display"] != undefined){
                    display_value = this.setEditorMapSet[fieldsToInclude[i] + "_display"];
                }

                includedFields += '<autosuggest '
                    + 'id-base="komet_mapping_set_editor_target_system" '
                    + 'id-postfix="_' + this.viewerID + '" '
                    + 'label="Target Code System:" '
                    + 'value="' + value + '" '
                    + 'display-value="' + display_value + '" '
                    + 'classes="komet-mapping-set-editor-edit" '
                    + 'suggestion-rest-variable="mapping_get_item_target_suggestions_path" '
                    + 'recents-rest-variable="mapping_get_item_target_recents_path" '
                    + '></autosuggest>'

            } else if (type == "text"){
                includedFields += label + '<input ' + name + id + 'class="' + classes + '" value="' + value + '">';

            } else if (type == "textarea"){
                includedFields += label + '<textarea ' + name + id + 'class="' + classes + '">' + value + '</textarea>';

            } else if (type == "select"){

                includedFields += label + '<select ' + name + id + 'class="' + classes + '">';

                var options = this.setEditorMapSet[fieldsToInclude[i]].options;

                for (var j = 0; j < options.length; j++){

                    includedFields += '<option';

                    if (options[j] == value){
                        includedFields += ' selected';
                    }

                    includedFields += '>' + options[j] + '</option>';
                }

                includedFields += '</select>';
            }

            includedFields += '<div class="komet-mapping-set-editor-display">' + value + '</div>';
            includedFields += '</div>';

            if (!even){
                includedFields += '</div>';
            }

        }

        // if the number of the included fields is odd, we need to close the last row started.
        if (fieldsToInclude.length % 2 !== 0){
            includedFields += '</div>';
        }

        // create a dom fragment from our included fields structure
        var documentFragment = document.createRange().createContextualFragment(includedFields);

        // append the dom fragment to the definition tab
        definitionTab.append(documentFragment);

        UIHelper.processAutoSuggestTags("#komet_mapping_set_editor_form_" + this.viewerID);

        // append the field sections we stored earlier into the row item we created for it and add it to our list of created fields
        //appendFields.forEach(function(fieldInfo){
        //
        //    definitionTab.find("." + addedTag + fieldInfo.tag_postfix).append(fieldInfo.field);
        //    this.setEditorCreatedFields.push(fieldInfo.tag_postfix);
        //}.bind(this));

    };

    MappingViewer.prototype.loadOverviewItemsGrid = function(){

        // If a grid already exists destroy it or it will create a second grid
        if (this.overviewItemsGridOptions) {
            this.overviewItemsGridOptions.api.destroy();
        }

        // disable item specific actions
        UIHelper.toggleFieldAvailability("komet_mapping_overview_item_delete_" + this.viewerID, false);
        UIHelper.toggleFieldAvailability("komet_mapping_overview_item_edit_" + this.viewerID, false);
        UIHelper.toggleFieldAvailability("komet_mapping_overview_item_comment_" + this.viewerID, false);

        // set the options for the result grid
        this.overviewItemsGridOptions = {
            enableColResize: true,
            enableSorting: true,
            suppressCellSelection: true,
            rowSelection: "single",
            onSelectionChanged: this.onOverviewItemsGridSelection,
            onRowDoubleClicked: this.onOverviewItemsGridDoubleClick,
            onGridReady: this.onGridReady,
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
                    {field: "status", headerName: "Status", hide: !this.showItemsSTAMP},
                    {field: "time", headerName: "Time", hide: !this.showItemsSTAMP},
                    {field: "author", headerName: "Author", hide: !this.showItemsSTAMP},
                    {field: "module", headerName: "Module", hide: !this.showItemsSTAMP},
                    {field: "path", headerName: "Path", hide: !this.showItemsSTAMP}
                ]
                }
            ]
        };

        new agGrid.Grid($("#komet_mapping_overview_items_" + this.viewerID).get(0), this.overviewItemsGridOptions);

        this.getOverviewItemsData();
    };

    MappingViewer.prototype.getOverviewItemsData = function(){

        // load the parameters from the form to add to the query string sent in the ajax data call
        var page_size = $("#komet_mapping_item_page_size_" + this.viewerID).val();
        var filter = $("#komet_mapping_item_filter_" + this.viewerID).val();
        var filterBy = $("#komet_mapping_item_filter_by_" + this.viewerID).val();
        var showActive = $("#komet_mapping_item_active_" + this.viewerID)[0].checked;
        var showInactive = $("#komet_mapping_item_inactive_" + this.viewerID)[0].checked;

        var searchParams = "?overview_set_id=" + this.currentSetID + "&overview_page_size=" + page_size + "&show_active=" + showActive + "&show_inactive=" + showInactive;

        if (filter != "") {
            searchParams += "&overview_items_filter=" + filter + "&filter_by=" + filterBy;
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
                    params.successCallback(search_results.data, search_results.total_number);
                }.bind(this));
            }.bind(this)
        };

        this.overviewItemsGridOptions.api.setDatasource(dataSource);

        // reload the recents menu
        //loadAssemblageRecents();
    };

    MappingViewer.prototype.onOverviewItemsGridSelection = function(){

        // enable item specific actions
        UIHelper.toggleFieldAvailability("komet_mapping_overview_item_delete_" + this.viewerID, true);
        UIHelper.toggleFieldAvailability("komet_mapping_overview_item_edit_" + this.viewerID, true);
        UIHelper.toggleFieldAvailability("komet_mapping_overview_item_comment_" + this.viewerID, true);

        var selectedRows = this.overviewItemsGridOptions.api.getSelectedRows();

        //selectedRows.forEach(function (selectedRow, index) {});
    }.bind(this);

    MappingViewer.prototype.onOverviewItemsGridDoubleClick = function(){

        var selectedRows = this.overviewItemsGridOptions.api.getSelectedRows();

        selectedRows.forEach(function (selectedRow, index) {
            console.log("Editing map item " + selectedRow.id);
        });
    }.bind(this);

    MappingViewer.prototype.onItemSourceSuggestionSelection = function(event, ui) {

        $("#komet_mapping_item_editor_source_display_" + this.viewerID).val(ui.item.label);
        $("#komet_mapping_item_editor_source_" + this.viewerID).val(ui.item.value);
        return false;
    }.bind(this);

    MappingViewer.prototype.onItemSourceSuggestionChange = function(event, ui) {

        if (!ui.item) {
            event.target.value = "";
            $("#komet_mapping_item_editor_source_" + this.viewerID).val("");
        }
    }.bind(this);

    MappingViewer.prototype.loadItemSourceRecents = function() {

        $.get(gon.routes.mapping_get_item_source_recents_path, function (data) {

            var options = "";

            $.each(data, function (index, value) {

                // use the html function to escape any html that may have been entered by the user
                var valueText = $("<li>").text(value.text).html();
                options += "<li><a href=\"#\" onclick=\"WindowManager.viewers[" + this.viewerID + "].useItemSourceRecent('" + value.id + "', '" + valueText + "')\">" + valueText + "</a></li>";
            }.bind(this));

            $("#komet_mapping_item_editor_source_recents_" + this.viewerID).html(options);
        }.bind(this));
    };

    MappingViewer.prototype.useItemSourceRecent = function(id, text) {

        $("#komet_mapping_item_editor_source_display_" + this.viewerID).val(text);
        $("#komet_mapping_item_editor_source_" + this.viewerID).val(id);
    }.bind(this);

    MappingViewer.prototype.onItemTargetSuggestionSelection = function(event, ui) {

        $("#komet_mapping_item_editor_target_display_" + this.viewerID).val(ui.item.label);
        $("#komet_mapping_item_editor_target_" + this.viewerID).val(ui.item.value);
        return false;
    }.bind(this);

    MappingViewer.prototype.onItemTargetSuggestionChange = function(event, ui) {

        if (!ui.item) {
            event.target.value = "";
            $("#komet_mapping_item_editor_target_" + this.viewerID).val("");
        }
    }.bind(this);

    MappingViewer.prototype.loadItemTargetRecents = function() {

        $.get(gon.routes.mapping_get_item_target_recents_path, function (data) {

            var options = "";

            $.each(data, function (index, value) {

                // use the html function to escape any html that may have been entered by the user
                var valueText = $("<li>").text(value.text).html();
                options += "<li><a href=\"#\" onclick=\"WindowManager.viewers[" + this.viewerID + "].useItemTargetRecent('" + value.id + "', '" + valueText + "')\">" + valueText + "</a></li>";
            }.bind(this));

            $("#komet_mapping_item_editor_target_recents_" + this.viewerID).html(options);
        }.bind(this));
    };

    MappingViewer.prototype.useItemTargetRecent = function(id, text) {

        $("#komet_mapping_item_editor_target_display_" + this.viewerID).val(text);
        $("#komet_mapping_item_editor_target_" + this.viewerID).val(id);
    }.bind(this);

    MappingViewer.prototype.toggleItemsSTAMP = function(){

        if (this.showItemsSTAMP) {

            this.showItemsSTAMP = false;
            this.overviewItemsGridOptions.columnApi.setColumnsVisible(["status", "time", "author", "module", "path"], false);
        } else {

            this.showItemsSTAMP = true;
            this.overviewItemsGridOptions.columnApi.setColumnsVisible(["status", "time", "author", "module", "path"], true);
        }

        this.overviewItemsGridOptions.api.sizeColumnsToFit();

    };

    MappingViewer.prototype.enterSetEditMode = function(){

        $(".komet-mapping-set-editor-display").hide();
        $(".komet-mapping-set-editor-edit:not(.komet-mapping-set-editor-create-only)").show();
    };

    MappingViewer.prototype.cancelSetEditMode = function(previousSetID){

        if (this.mappingAction == MappingModule.CREATE_SET){

            if (previousSetID != ""){
                MappingModule.callLoadViewerData(previousSetID, MappingModule.SET_DETAILS, this.viewerID);
            } else {
                MappingModule.callLoadViewerData(null, MappingModule.SET_LIST, this.viewerID);
            }

            return;
        }

        $(".komet-mapping-set-editor-display").show();
        $(".komet-mapping-set-editor-edit").hide();

        console.log("Had Changes: " + UIHelper.hasFormChanged("#komet_mapping_set_editor_form_" + this.viewerID));
        UIHelper.resetFormChanges("#komet_mapping_set_editor_form_" + this.viewerID);
    };

    MappingViewer.prototype.showIncludeSetFieldsDialog = function(){

        var dialog = $('#komet_mapping_dialog_add_set_fields_' + this.viewerID);
        dialog.removeClass("hide");
        dialog.position({my: "right top", at: "right bottom", of: "#komet_mapping_set_editor_save_" + this.viewerID});
    };

    MappingViewer.prototype.cancelIncludeSetFieldsDialog = function(){

        var dialog = $('#komet_mapping_dialog_add_set_fields_' + this.viewerID);
        dialog.addClass("hide");

        UIHelper.resetFormChanges("#komet_mapping_dialog_add_set_fields_" + this.viewerID);
    };

    MappingViewer.prototype.saveIncludeSetFieldsDialog = function(){

        var dialog = $('#komet_mapping_dialog_add_set_fields_' + this.viewerID);
        dialog.addClass("hide");

        UIHelper.acceptFormChanges("#komet_mapping_dialog_add_set_fields_" + this.viewerID);
        this.generateSetEditorAdditionalFields();

        $("#komet_mapping_set_editor_form_" + this.viewerID).find(".komet-mapping-set-editor-display").hide();
    };

    MappingViewer.prototype.openItemEditor = function(newItem) {

        var url = gon.routes.mapping_map_item_editor_path + "?set_id=" + $("#komet_mapping_set_editor_set_id_" + this.viewerID).val() + "&viewer_id=" + this.viewerID;

        if (!newItem) {
            url += "&item_id=" + this.overviewItemsGridOptions.api.getSelectedRows()[0].id;
        }

        this.itemEditorWindow = window.open(url, "MapItemEditor", "width=1010,height=680");
    };

    MappingViewer.prototype.initializeItemEditor = function() {

        // setup the source field autocomplete functionality
        $("#komet_mapping_item_editor_source_display_" + this.viewerID).autocomplete({
            source: gon.routes.mapping_get_item_source_suggestions_path,
            minLength: 3,
            select: this.onItemSourceSuggestionSelection,
            change: this.onItemSourceSuggestionChange
        });

        this.loadItemSourceRecents();

        // setup the target field autocomplete functionality
        $("#komet_mapping_item_editor_target_display_" + this.viewerID).autocomplete({
            source: gon.routes.mapping_get_item_target_suggestions_path,
            minLength: 3,
            select: this.onItemTargetSuggestionSelection,
            change: this.onItemTargetSuggestionChange
        });

        this.loadItemTargetRecents();

        // setup the Kind Of field autocomplete functionality
        $("#komet_mapping_item_editor_kind_of_display_" + this.viewerID).autocomplete({
            source: gon.routes.mapping_get_item_kind_of_suggestions_path,
            minLength: 3,
            select: this.onItemKindOfSuggestionSelection,
            change: this.onItemKindOfSuggestionChange
        });

        this.loadItemKindOfRecents();

        var thisViewer = this;

        // set the form to post the data to the controller and upon success reload the Items grid and close the window.
        $("#komet_mapping_item_editor_form_" + this.viewerID).submit(function () {
            window.opener.console.log("Hello");
            $.ajax({
                type: "POST",
                url: $(this).attr("action"),
                data: $(this).serialize(), //new FormData($(this)[0]),
                success: function () {

                    console.log("viewer: " + thisViewer.viewerID);
                    window.opener.console.log("Success!");
                    window.opener.WindowManager.viewers[thisViewer.viewerID].loadOverviewItemsGrid($("#komet_mapping_item_editor_set_id_" + thisViewer.viewerID).val());
                    window.close();
                }
            });

            // have to return false to stop the form from posting twice.
            return false;
        });

        this.loadTargetCandidatesGrid();
    };

    MappingViewer.prototype.onItemKindOfSuggestionSelection = function(event, ui) {

        $("#komet_mapping_item_editor_kind_of_display_" + this.viewerID).val(ui.item.label);
        $("#komet_mapping_item_editor_kind_of_" + this.viewerID).val(ui.item.value);
        return false;
    }.bind(this);

    MappingViewer.prototype.onItemKindOfSuggestionChange = function(event, ui) {

        if (!ui.item) {
            event.target.value = "";
            $("#komet_mapping_item_editor_kind_of_" + this.viewerID).val("");
        }
    }.bind(this);

    MappingViewer.prototype.loadItemKindOfRecents = function() {

        $.get(gon.routes.mapping_get_item_kind_of_recents_path, function (data) {

            var options = "";

            $.each(data, function (index, value) {

                // use the html function to escape any html that may have been entered by the user
                var valueText = $("<li>").text(value.text).html();
                options += "<li><a href=\"#\" onclick=\"WindowManager.viewers[" + this.viewerID + "].useItemKindOfRecent('" + value.id + "', '" + valueText + "')\">" + valueText + "</a></li>";
            }.bind(this));

            $("#komet_mapping_item_editor_kind_of_recents_" + this.viewerID).html(options);
        }.bind(this));
    };

    MappingViewer.prototype.useItemKindOfRecent = function(id, text) {

        $("#komet_mapping_item_editor_kind_of_display_" + this.viewerID).val(text);
        $("#komet_mapping_item_editor_kind_of_" + this.viewerID).val(id);
    }.bind(this);

    MappingViewer.prototype.loadTargetCandidatesGrid = function(showData) {

        // If a grid already exists destroy it or it will create a second grid
        if (this.targetCandidatesGridOptions) {
            this.targetCandidatesGridOptions.api.destroy();
        }

        // set the options for the result grid
        this.targetCandidatesGridOptions = {
            enableColResize: true,
            enableSorting: true,
            suppressCellSelection: true,
            rowSelection: "single",
            onSelectionChanged: this.onTargetCandidatesGridSelection,
            onGridReady: this.onGridReady,
            rowModelType: 'pagination',
            columnDefs: [
                {field: "id", headerName: "id", hide: "true"},
                {field: "concept", headerName: "Concept"},
                {field: "code_system", headerName: "Code System"},
                {field: "status", headerName: "Status"}
            ]
        };

        new agGrid.Grid($("#komet_mapping_item_editor_target_candidates_" + this.viewerID).get(0), this.targetCandidatesGridOptions);

        if (showData == undefined) {
            this.targetCandidatesGridOptions.api.showNoRowsOverlay()
        } else {
            this.getTargetCandidatesData();
        }
    };

    MappingViewer.prototype.getTargetCandidatesData = function() {

        $("#komet_taxonomy_search_form_" + this.viewerID).find(".komet-form-error").remove();

        var search_text = $("#komet_mapping_item_editor_target_candidates_search_" + this.viewerID).val();

        if (search_text === ""){

            $("#komet_mapping_item_editor_target_candidates_search_section_" + this.viewerID).after(UIHelper.generateFormErrorMessage("Candidate Criteria cannot be blank."));
            return;
        }

        // load the parameters from the form to add to the query string sent in the ajax data call
        var page_size = $("#komet_mapping_item_editor_target_candidates_page_size_" + this.viewerID).val();
        var description_type = $("#komet_mapping_item_editor_description_type_" + this.viewerID).val();
        var advanced_description_type = $("#komet_mapping_item_editor_advanced_description_type_" + this.viewerID).val();
        var code_system = $("#komet_mapping_item_editor_code_system_" + this.viewerID).val();
        var assemblage = $("#komet_mapping_item_editor_assemblage_" + this.viewerID).val();
        var kind_of = $("#komet_mapping_item_editor_kind_of_" + this.viewerID).val();

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
                }.bind(this));
            }.bind(this)
        };

        this.targetCandidatesGridOptions.api.setDatasource(dataSource);
    };

    MappingViewer.prototype.onTargetCandidatesGridSelection = function() {

        var selectedRows = this.targetCandidatesGridOptions.api.getSelectedRows();

        selectedRows.forEach(function (selectedRow, index) {

            $("#komet_mapping_item_editor_target_" + this.viewerID).val(selectedRow.id);
            $("#komet_mapping_item_editor_target_display_" + this.viewerID).val(selectedRow.concept);
        });
    }.bind(this);

    // call our constructor function
    this.init(viewerID, currentSetID, mappingAction)
};
