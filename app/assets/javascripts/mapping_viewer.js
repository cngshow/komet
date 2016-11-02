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
    
var MappingViewer = function(viewerID, currentSetID, viewerAction) {

    MappingViewer.prototype.init = function(viewerID, currentSetID, viewerAction) {

        this.viewerID = viewerID;
        this.currentSetID = currentSetID;
        this.panelStates = {};
        this.overviewSetsGridOptions = null;
        this.overviewItemsGridOptions = null;
        this.targetCandidatesGridOptions = null;
        this.showOverviewInactiveConcepts = null;
        this.showSTAMP = false;
        this.showItemsSTAMP = false;
        this.itemEditorWindow = null;
        this.viewerAction = viewerAction;
        this.setEditorCreatedFields = [];
        this.setEditorMapSet = {};
        this.INCLUDE_FIELD_CLASS_PREFIX = "komet-mapping-added-";
        this.SET_INCLUDE_FIELD_PREFIX = "komet_mapping_set_editor_include_fields_";
        this.SET_INCLUDE_FIELD_CHECKBOX_SECTION = "komet_mapping_set_editor_select_included_fields_" + viewerID;
        this.SET_INCLUDE_FIELD_DIALOG = "komet_mapping_set_editor_add_set_fields_" + viewerID;
        this.ITEMS_INCLUDE_FIELD_PREFIX = "komet_mapping_set_editor_items_include_fields_";
        this.ITEMS_INCLUDE_FIELD_CHECKBOX_SECTION = "komet_mapping_set_editor_items_select_included_fields_" + viewerID;
        this.ITEMS_INCLUDE_FIELD_DIALOG = "komet_mapping_set_editor_items_add_set_fields_" + viewerID;
        this.SET_EDITOR_FORM = "komet_mapping_set_editor_form_" + viewerID;
        this.LINKED_TEXT = "Viewer linked to Mapping Tree. Click to unlink.";
        this.UNLINKED_TEXT = "Viewer not linked to Mapping Tree. Click to link.";
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

        if (linked){
            linkIcon.parent().attr("title", this.LINKED_TEXT);
        } else {
            linkIcon.parent().attr("title", this.UNLINKED_TEXT);
        }

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

        if (this.showSTAMP){
            $("#komet_mapping_show_stamp_" + this.viewerID)[0].checked = true;
        }

        // disable map set specific actions
        this.setOverviewSetsGridActions(null);

        // set the options for the result grid
        this.overviewSetsGridOptions = {
            enableColResize: true,
            enableSorting: true,
            suppressCellSelection: true,
            rowSelection: "single",
            onSelectionChanged: this.onOverviewSetsGridSelection,
            onRowDoubleClicked: this.onOverviewSetsGridDoubleClick,
            onGridReady: this.onGridReady,
            rowModelType: 'normal',
            columnDefs: [
                {field: "set_id", headerName: 'ID', hide: 'true'},
                {field: "name", headerName: 'Name'},
                {field: "description", headerName: "Description"},
                {
                    groupId: "stamp", headerName: "STAMP Fields", children: [
                    {field: "state", headerName: "State", hide: !this.showSTAMP},
                    {field: "time", headerName: "Time", hide: !this.showSTAMP},
                    {field: "author", headerName: "Author", hide: !this.showSTAMP},
                    {field: "module", headerName: "Module", hide: !this.showSTAMP},
                    {field: "path", headerName: "Path", hide: !this.showSTAMP}
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

        var selectedRows = this.overviewSetsGridOptions.api.getSelectedRows();

        // enable map set specific actions
        selectedRows.forEach(function (selectedRow) {
            this.setOverviewSetsGridActions(selectedRow);
        }.bind(this));

    }.bind(this);

    MappingViewer.prototype.onOverviewSetsGridDoubleClick = function(){
        this.loadOverviewSetsGridSelectedSet();
    }.bind(this);

    MappingViewer.prototype.onGridReady = function(event){
        event.api.sizeColumnsToFit();
    };

    MappingViewer.prototype.setOverviewSetsGridActions = function(selectedRow){

        var editParent = $("#komet_mapping_overview_set_edit_" + this.viewerID).parent();
        var stateIcon = $("#komet_mapping_overview_set_state_" + this.viewerID);
        var stateParent = stateIcon.parent();

        if (selectedRow != null) {

            UIHelper.toggleFieldAvailability(editParent, true);

            var stateTitle = "Inactivate Selected Map Set";
            var stateClass = "glyphicon glyphicon-ban-circle";
            var stateValue = "false";
            var stateOnClick = "UIHelper.changeConceptState(null, '" + selectedRow.set_id + "', '" + selectedRow.name + "', 'false')()";

            if (selectedRow.state.toLowerCase() == "inactive") {

                stateTitle = "Activate Selected Map Set";
                stateClass = "glyphicon glyphicon-ok-circle";
                stateValue = "true";
                stateOnClick = "UIHelper.changeConceptState(null, '" + selectedRow.set_id + "', '" + selectedRow.name + "', 'true')()";

            }

            stateIcon.css(stateClass);
            stateIcon.attr({"title": stateTitle, "class": stateClass});
            stateParent.attr({"title": stateTitle, "data-state": stateValue, "onclick": stateOnClick});
            stateParent.removeClass("hide");

            UIHelper.toggleFieldAvailability(stateParent, true);

        } else {

            stateParent[0].classList.add('hide');
            UIHelper.toggleFieldAvailability(editParent, false);
        }
    };

    MappingViewer.prototype.loadOverviewSetsGridSelectedSet = function(action){

        var selectedRows = this.overviewSetsGridOptions.api.getSelectedRows();

        selectedRows.forEach(function (selectedRow) {
            $.publish(KometChannels.Mapping.mappingTreeNodeSelectedChannel, [null, selectedRow.set_id, this.viewerID, WindowManager.INLINE, action]);
        }.bind(this));
    };

    MappingViewer.prototype.toggleSTAMP = function(){

        var stampControl = $("#komet_mapping_show_stamp_" + this.viewerID);

        if (stampControl[0].checked) {

            this.showSTAMP = true;
            this.overviewSetsGridOptions.columnApi.setColumnsVisible(["state", "time", "author", "module", "path"], true);
        } else {

            this.showSTAMP = false;
            this.overviewSetsGridOptions.columnApi.setColumnsVisible(["state", "time", "author", "module", "path"], false);
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

    MappingViewer.prototype.initializeSetEditor = function(viewerAction){

        var form = $("#komet_mapping_set_editor_form_" + this.viewerID);

        this.viewerAction = viewerAction;
        this.setEditorOriginalIncludedFields = null;
        this.setEditorOriginalItemsIncludedFields = null;

        var includeFields = "";

        for (var i = 0; i < this.setEditorMapSet["include_fields"].length; i++){
            includeFields += this.generateSetEditorDialogIncludeSection(this.setEditorMapSet["include_fields"][i], this.setEditorMapSet[this.setEditorMapSet["include_fields"][i]])
        }

        // create a dom fragment from our included fields structure and append it to the dialog form
        $("#" + this.SET_INCLUDE_FIELD_CHECKBOX_SECTION).append(document.createRange().createContextualFragment(includeFields));

        this.generateSetEditorAdditionalFields();

        var includeItemFields = "";

        for (var i = 0; i < this.setEditorMapSet["item_fields"].length; i++){
            includeItemFields += this.generateSetEditorItemsDialogIncludeSection(this.setEditorMapSet["item_fields"][i], this.setEditorMapSet["item_field_" + this.setEditorMapSet["item_fields"][i]])
        }

        // create a dom fragment from our included fields structure and append it to the dialog form
        $("#" + this.ITEMS_INCLUDE_FIELD_CHECKBOX_SECTION).append(document.createRange().createContextualFragment(includeItemFields));

        this.generateSetEditorItemsAdditionalFields();

        if (viewerAction == MappingModule.SET_DETAILS){

            form.find(".komet-mapping-set-editor-edit").hide();

            if (this.currentSetID != null && this.currentSetID != ""){

                this.loadOverviewItemsGrid();
                UIHelper.toggleFieldAvailability("#komet_mapping_overview_item_create_" + this.viewerID, true);
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

    /********* Map Set Additional Fields Methods */

    MappingViewer.prototype.generateSetEditorDialogIncludeSection = function(fieldName, fieldInfo){

        var sectionString = '<div class="' + this.INCLUDE_FIELD_CLASS_PREFIX + fieldName + '">'
            + '<input type="checkbox" name="' + this.SET_INCLUDE_FIELD_PREFIX.slice(0, -1) + '[]" class="form-control" '
            + 'id="' + this.SET_INCLUDE_FIELD_PREFIX + fieldName + '_' + this.viewerID + '" value="' + fieldName + '" ';

        if (fieldInfo.display){
            sectionString += 'checked="checked"';
        }

        sectionString += '><label for="' + this.SET_INCLUDE_FIELD_PREFIX + fieldName + '_' + this.viewerID + '">' + fieldInfo.label_display + '</label>';

        if (fieldInfo.removable){
            sectionString += '<div class="glyphicon glyphicon-remove komet-flex-right" title="Remove Field" onclick="WindowManager.viewers[' + this.viewerID + '].removeSetIncludedField(\'' + fieldName + '\');"></div>';
        }

        sectionString += '<input type="hidden" name="' + this.SET_INCLUDE_FIELD_PREFIX + fieldName + '_label" value="' + fieldInfo.label + '">'
            + '<input type="hidden" name="' + this.SET_INCLUDE_FIELD_PREFIX + fieldName + '_data_type" value="' + fieldInfo.data_type + '">'
            + '<input type="hidden" name="' + this.SET_INCLUDE_FIELD_PREFIX + fieldName + '_required" value="' + fieldInfo.required + '">'
            + '<input type="hidden" name="' + this.SET_INCLUDE_FIELD_PREFIX + fieldName + '_removable" value="' + fieldInfo.removable + '">'
            + '</div>';

        return sectionString;
    };

    MappingViewer.prototype.getSetEditorIncludeFields = function(state){

        var includeCheckboxes = $("#" + this.SET_INCLUDE_FIELD_DIALOG).find("[name='komet_mapping_set_editor_include_fields[]']");

        if (state == "selected"){
            includeCheckboxes = includeCheckboxes.filter(":checked");
        } else if (state == "unselected"){
            includeCheckboxes = includeCheckboxes.not(":checked");
        }

        return includeCheckboxes;
    };

    MappingViewer.prototype.generateSetEditorAdditionalFields = function(){

        // remove all added fields from the form so we can start fresh
        var definitionTab = $("#komet_mapping_set_definition_tab_" + this.viewerID);
        definitionTab.find(".komet-mapping-set-added-row").remove();

        var fieldsToInclude = $.map(this.getSetEditorIncludeFields("selected"), function(element) {
            return element.value;
        });

        var includedFields = "";
        var addedTag = "komet-mapping-set-added-";

        // build up the structure for displaying the included fields
        for (var i = 0; i < fieldsToInclude.length; i++){

            var even = (i % 2 === 0);

            // if the number of the included fields is even we need to start a new row
            if (even){
                includedFields += '<div class="komet-mapping-set-definition-row komet-mapping-set-added-row">';
            }

            includedFields += '<div class="komet-mapping-set-definition-item ' + addedTag + fieldsToInclude[i] + '">';

            var idPrefix = "komet_mapping_set_editor_";
            var name = idPrefix + fieldsToInclude[i];
            var id = name + '_' + this.viewerID;
            var classes = "form-control komet-mapping-set-editor-edit komet-mapping-set-editor-create-only";
            var value = "";
            var dataType = "STRING";
            var labelValue = fieldsToInclude[i];
            var labelDisplayValue = fieldsToInclude[i];
            var required = false;

            if (this.setEditorMapSet[fieldsToInclude[i]] != undefined){

                value = this.setEditorMapSet[fieldsToInclude[i]].value;
                dataType = this.setEditorMapSet[fieldsToInclude[i]].data_type;
                labelValue = this.setEditorMapSet[fieldsToInclude[i]].label;
                labelDisplayValue = this.setEditorMapSet[fieldsToInclude[i]].label_display;
                required = this.setEditorMapSet[fieldsToInclude[i]].required;
            }

            var label = '<label for="' + fieldsToInclude[i] + '_' + this.viewerID + '">' + labelDisplayValue + ':</label>';

            if (dataType == "UUID"){

                var displayValue = "";

                if (this.setEditorMapSet[fieldsToInclude[i] + "_display"] != undefined){
                    displayValue = this.setEditorMapSet[fieldsToInclude[i] + "_display"];
                }

                includedFields += '<autosuggest '
                    + 'id-base="' + idPrefix + fieldsToInclude[i] + '" '
                    + 'id-postfix="_' + this.viewerID + '" '
                    + 'value="' + labelValue + '" '
                    + 'label="' + labelDisplayValue + ':" '
                    + 'display-value="' + displayValue + '" '
                    + 'classes="komet-mapping-set-editor-edit komet-mapping-set-editor-create-only" '
                    + '></autosuggest>';

                value = displayValue;

            } else if (dataType == "BOOLEAN"){
                includedFields += label + UIHelper.createSelectFieldString(id, name, classes, UIHelper.getPreDefinedOptionsForSelect("true_false"), value);
            } else {
                includedFields += label + '<input name="' + name + '" id="' + id + '" class="' + classes + '" value="' + value + '">';
            }

            includedFields += '<div class="komet-mapping-set-editor-display komet-mapping-set-editor-create-only">' + value + '</div>';

            // close the definition-item
            includedFields += '</div>';

            // if the number of the included fields is odd we need to close the row
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
    };

    MappingViewer.prototype.showIncludeSetFieldsDialog = function(){

        var dialog = $('#' + this.SET_INCLUDE_FIELD_DIALOG);
        dialog.removeClass("hide");
        dialog.position({my: "right top", at: "right bottom", of: "#komet_mapping_set_editor_save_" + this.viewerID});

        if (this.setEditorOriginalIncludedFields == null) {

            this.setEditorOriginalIncludedFields = $("#" + this.SET_INCLUDE_FIELD_CHECKBOX_SECTION).html();
        }
    };

    MappingViewer.prototype.cancelIncludeSetFieldsDialog = function(){

        var dialog = $('#' + this.SET_INCLUDE_FIELD_DIALOG);
        dialog.addClass("hide");

        UIHelper.resetFormChanges("#" + this.SET_INCLUDE_FIELD_DIALOG);
    };

    MappingViewer.prototype.saveIncludeSetFieldsDialog = function(){

        var dialog = $('#' + this.SET_INCLUDE_FIELD_DIALOG);
        dialog.addClass("hide");

        var prefix = "#komet_mapping_set_editor_add_fields_";
        $(prefix + "data_type_" + this.viewerID).val("STRING");
        $(prefix + "label_" + this.viewerID).val("");
        $(prefix + "label_display_" + this.viewerID).val("");
        $(prefix + "required_" + this.viewerID)[0].checked = false;

        UIHelper.acceptFormChanges("#" + this.SET_INCLUDE_FIELD_DIALOG);

        this.generateSetEditorAdditionalFields();
        $("#komet_mapping_set_editor_form_" + this.viewerID).find(".komet-mapping-set-editor-display").hide();
    };

    MappingViewer.prototype.removeSetIncludedField = function(fieldName){

        // remove the field section from the dialog included fields
        $("#" + this.SET_INCLUDE_FIELD_CHECKBOX_SECTION).find($("." + this.INCLUDE_FIELD_CLASS_PREFIX + fieldName)).remove();

        // remove the field information from the map set info javascript variable, both the field information and from the include fields array
        this.setEditorMapSet["include_fields"].splice(this.setEditorMapSet["include_fields"].indexOf(fieldName), 1);
        delete this.setEditorMapSet[fieldName];
    };

    MappingViewer.prototype.addSetField = function(){

        UIHelper.removePageMessages("#" + this.SET_INCLUDE_FIELD_DIALOG);

        var prefix = "#komet_mapping_set_editor_add_fields_";
        var dataTypeField = $(prefix + "data_type_" + this.viewerID);
        var labelField = $(prefix + "label_" + this.viewerID);
        var labelDisplayField = $(prefix + "label_display_" + this.viewerID);
        var requiredField = $(prefix + "required_" + this.viewerID);

        if (dataTypeField.val() == "" || labelField.val() == ""){

            $(prefix + "options_section_" + this.viewerID).after(UIHelper.generatePageMessage("All fields must be filled in."));
            return;
        }

        // make sure there are no invalid characters in the name
        // var name = labelDisplayField.val().replace(/[^a-zA-Z0-9_\-]/g, '').toLowerCase();
        var name = labelField.val();

        if (this.setEditorMapSet.include_fields.indexOf(name) >= 0){

            $(prefix + "options_section_" + this.viewerID).after(UIHelper.generatePageMessage("The label must be unique. There is another field in this mapset with this label."));
            return;
        }

        var fieldInfo = {"name": name,
            "data_type": dataTypeField.val(),
            "label": labelField.val(),
            "label_display": labelDisplayField.val().replace(/[^a-zA-Z0-9_,\- ]+/g, ''),
            "required": requiredField[0].checked,
            "value": "",
            "removable": true,
            "display": true
        };

        this.setEditorMapSet.include_fields.push(name);
        this.setEditorMapSet[name] = fieldInfo;

        var newSection = this.generateSetEditorDialogIncludeSection(name, fieldInfo);

        // create a dom fragment from our generated structure and append it to the dialog form
        $("#" + this.SET_INCLUDE_FIELD_CHECKBOX_SECTION).append(document.createRange().createContextualFragment(newSection));

        dataTypeField.val("STRING");
        labelField.val("");
        labelDisplayField.val("");
        requiredField[0].checked = false;
    };

    /********* Set Item Additional Fields Methods */

    MappingViewer.prototype.generateSetEditorItemsDialogIncludeSection = function(fieldName, fieldInfo){

        var sectionString = '<div class="' + this.INCLUDE_FIELD_CLASS_PREFIX + fieldName + '">'
            + '<input type="checkbox" name="' + this.ITEMS_INCLUDE_FIELD_PREFIX.slice(0, -1) + '[]" class="form-control" '
            + 'id="' + this.ITEMS_INCLUDE_FIELD_PREFIX + fieldName + '_' + this.viewerID + '" value="' + fieldName + '" ';

        if (fieldInfo.display){
            sectionString += 'checked="checked"';
        }

        sectionString += '><label for="' + this.ITEMS_INCLUDE_FIELD_PREFIX + fieldName + '_' + this.viewerID + '">' + fieldInfo.label_display + '</label>';

        if (fieldInfo.removable){
            sectionString += '<div class="glyphicon glyphicon-remove komet-flex-right" title="Remove Field" onclick="WindowManager.viewers[' + this.viewerID + '].removeSetItemsIncludedField(\'' + fieldName + '\');"></div>';
        }

        sectionString += '<input type="hidden" name="' + this.ITEMS_INCLUDE_FIELD_PREFIX + fieldName + '_label" value="' + fieldInfo.label + '">'
            + '<input type="hidden" name="' + this.ITEMS_INCLUDE_FIELD_PREFIX + fieldName + '_data_type" value="' + fieldInfo.data_type + '">'
            + '<input type="hidden" name="' + this.SET_INCLUDE_FIELD_PREFIX + fieldName + '_required" value="' + fieldInfo.required + '">'
            + '<input type="hidden" name="' + this.ITEMS_INCLUDE_FIELD_PREFIX + fieldName + '_removable" value="' + fieldInfo.removable + '">'
            + '</div>';

        return sectionString;
    };

    MappingViewer.prototype.getSetEditorItemsIncludeFields = function(state){


        var includeCheckboxes = $("#" + this.ITEMS_INCLUDE_FIELD_DIALOG).find("[name='komet_mapping_set_editor_items_include_fields[]']");

        if (state == "selected"){
            includeCheckboxes = includeCheckboxes.filter(":checked");
        } else if (state == "unselected"){
            includeCheckboxes = includeCheckboxes.not(":checked");
        }

        return includeCheckboxes;
    };

    MappingViewer.prototype.generateSetEditorItemsAdditionalFields = function(){

        // remove all added fields from the form so we can start fresh
        var definitionTab = $("#komet_mapping_set_items_tab_" + this.viewerID);
        definitionTab.find(".komet-mapping-set-added-row").remove();

        var fieldsToInclude = $.map(this.getSetEditorItemsIncludeFields("selected"), function(element) {
            return element.value;
        });

        var includedFields = "";
        var addedTag = "komet-mapping-set-added-";

        // build up the structure for displaying the included fields
        for (var i = 0; i < fieldsToInclude.length; i++){

            var even = (i % 2 === 0);

            // if the number of the included fields is even we need to start a new row
            if (even){
                includedFields += '<div class="komet-mapping-set-definition-row komet-mapping-set-added-row">';
            }

            includedFields += '<div class="komet-mapping-set-definition-item ' + addedTag + fieldsToInclude[i] + '">';

            var fieldInfo = this.setEditorMapSet["item_field_" + fieldsToInclude[i]];

            var idPrefix = "komet_mapping_set_editor_items_";
            var name = 'name="' + idPrefix + fieldsToInclude[i]+ ' ';
            var id = 'id="' + idPrefix + fieldsToInclude[i] + '_' + this.viewerID + ' ';
            var data_type = "STRING";
            var labelValue = fieldsToInclude[i];
            var labelDisplayValue = fieldsToInclude[i];
            var required = false;

            if (fieldInfo != undefined){

                data_type = fieldInfo.type;
                labelValue = fieldInfo.label;
                labelDisplayValue = fieldInfo.label_display;
                required = fieldInfo.required;
            }

            includedFields +=  '<div><b>Name:</b> ' + labelDisplayValue + '</div>';
            includedFields +=  '<div><b>Data Type:</b> ' + data_type + '</div>';
            includedFields +=  '<div><b>Required:</b> ' + required + '</div>';

            // close the definition-item
            includedFields += '</div>';

            // if the number of the included fields is odd we need to close the row
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
    };

    MappingViewer.prototype.showIncludeSetItemsFieldsDialog = function(){

        var dialog = $('#' + this.ITEMS_INCLUDE_FIELD_DIALOG);
        dialog.removeClass("hide");
        dialog.position({my: "right top", at: "right bottom", of: "#komet_mapping_set_editor_save_" + this.viewerID});

        if (this.setEditorOriginalItemsIncludedFields == null) {

            this.setEditorOriginalItemsIncludedFields = $("#" + this.ITEMS_INCLUDE_FIELD_CHECKBOX_SECTION).html();
        }
    };

    MappingViewer.prototype.cancelIncludeSetItemsFieldsDialog = function(){

        var dialog = $('#' + this.ITEMS_INCLUDE_FIELD_DIALOG);
        dialog.addClass("hide");

        UIHelper.resetFormChanges("#" + this.ITEMS_INCLUDE_FIELD_DIALOG);
    };

    MappingViewer.prototype.saveIncludeSetItemsFieldsDialog = function(){

        var dialog = $('#' + this.ITEMS_INCLUDE_FIELD_DIALOG);
        dialog.addClass("hide");

        var prefix = "#komet_mapping_set_editor_add_fields_";
        $(prefix + "data_type_" + this.viewerID).val("STRING");
        $(prefix + "label_" + this.viewerID).val("");
        $(prefix + "label_display_" + this.viewerID).val("");
        $(prefix + "required_" + this.viewerID)[0].checked = false;

        UIHelper.acceptFormChanges("#" + this.ITEMS_INCLUDE_FIELD_DIALOG);

        this.generateSetEditorItemsAdditionalFields();
    };

    MappingViewer.prototype.removeSetItemsIncludedField = function(fieldName){

        // remove the field section from the dialog included fields
        $("#" + this.ITEMS_INCLUDE_FIELD_CHECKBOX_SECTION).find($("." + this.INCLUDE_FIELD_CLASS_PREFIX + fieldName)).remove();

        // remove the field information from the map set info javascript variable, both the field information and from the include fields array
        this.setEditorMapSet["item_fields"].splice(this.setEditorMapSet["item_fields"].indexOf(fieldName), 1);
        delete this.setEditorMapSet["item_field_" + fieldName];
    };

    MappingViewer.prototype.addSetItemsField = function(){

        UIHelper.removePageMessages("#" + this.ITEMS_INCLUDE_FIELD_DIALOG);

        var prefix = "#komet_mapping_set_editor_items_add_fields_";
        var dataTypeField = $(prefix + "data_type_" + this.viewerID);
        var labelField = $(prefix + "label_" + this.viewerID);
        var labelDisplayField = $(prefix + "label_display_" + this.viewerID);
        var requiredField = $(prefix + "required_" + this.viewerID);

        if (dataTypeField.val() == "" || labelField.val() == ""){

            $(prefix + "options_section_" + this.viewerID).after(UIHelper.generatePageMessage("All fields must be filled in."));
            return;
        }

        // make sure there are no invalid characters in the name
        // var name = labelDisplayField.val().replace(/[^a-zA-Z0-9_\-]/g, '').toLowerCase();
        var name = labelField.val();

        if (this.setEditorMapSet.item_fields.indexOf(name) >= 0){

            $(prefix + "options_section_" + this.viewerID).after(UIHelper.generatePageMessage("The label must be unique. There is another field in this mapset with this label."));
            return;
        }

        var fieldInfo = {"name": name,
            "data_type": dataTypeField.val(),
            "label": labelField.val(),
            "label_display": labelDisplayField.val().replace(/[^a-zA-Z0-9_,\- ]+/g, ''),
            "required": requiredField[0].checked,
            "removable": true,
            "display": true
        };


        this.setEditorMapSet.item_fields.push(name);
        this.setEditorMapSet["item_field_" + name] = fieldInfo;

        var newSection = this.generateSetEditorItemsDialogIncludeSection(name, fieldInfo);

        // create a dom fragment from our generated structure and append it to the dialog form
        $("#" + this.ITEMS_INCLUDE_FIELD_CHECKBOX_SECTION).append(document.createRange().createContextualFragment(newSection));

        dataTypeField.val("STRING");
        labelField.val("");
        labelDisplayField.val("");
        requiredField[0].checked = false;
    };

    MappingViewer.prototype.itemsGridCellRenderer = function(params){
        
        var fieldInfo = this.overviewItemsGridOptions.column_definitions[params.colDef.field];

        var idPrefix = "komet_mapping_set_editor_item_";
        var name = 'name="' + idPrefix + fieldInfo.item_id + '_' + fieldInfo.name+ ' ';
        var id = 'id="' + idPrefix + fieldInfo.item_id + '_' + fieldInfo.name + '_' + this.viewerID + ' ';
        var classes = "form-control komet-mapping-set-editor-edit";
        var value = params.value;
        var dataType = fieldInfo.data_type;
        var cellContents = "";

        if (dataType == "UUID"){

            var displayValue = "";

            if (params.data[fieldInfo.name + "_display"] != undefined){
                displayValue = params.data[fieldInfo.name + "_display"];
            }

            cellContents += '<autosuggest '
                + 'id-base="' + idPrefix + fieldInfo.name + '" '
                + 'id-postfix="_' + this.viewerID + '" '
                + 'value="' + value + '" '
                + 'display-value="' + displayValue + '" '
                + 'classes="komet-mapping-set-editor-edit" '
                + '></autosuggest>';

            value = displayValue;

        } else if (dataType == "BOOLEAN"){

            cellContents += UIHelper.createSelectFieldString(id, name, classes, UIHelper.getPreDefinedOptionsForSelect("true_false"), value);
        } else {
            cellContents += '<input ' + name + id + 'class="' + classes + '" value="' + value + '">';
        }

       // cellContents += '<div class="komet-mapping-set-editor-display">' + value + '</div>';

        return cellContents;

    }.bind(this);

    MappingViewer.prototype.loadOverviewItemsGrid = function(){

        // If a grid already exists destroy it or it will create a second grid
        if (this.overviewItemsGridOptions) {
            this.overviewItemsGridOptions.api.destroy();
        }

        // disable item specific actions
        UIHelper.toggleFieldAvailability("#komet_mapping_overview_item_delete_" + this.viewerID, false);
        UIHelper.toggleFieldAvailability("#komet_mapping_overview_item_edit_" + this.viewerID, false);
        UIHelper.toggleFieldAvailability("#komet_mapping_overview_item_comment_" + this.viewerID, false);

        // set the options for the result grid
        this.overviewItemsGridOptions = {
            enableColResize: true,
            enableSorting: false,
            suppressCellSelection: true,
            rowSelection: "single",
            onRowSelected: this.onOverviewItemsGridSelection,
            onRowDoubleClicked: this.onOverviewItemsGridDoubleClick,
            onGridReady: this.onGridReady,
            rowModelType: 'normal',
            rowHeight: 30,
            columnDefs: [
                {field: "item_id", headerName: "id", hide: "true"},
                {field: "source_concept", headerName: 'Source ID', hide: "false"},
                {field: "source_concept_display", headerName: "Source Concept"},
                {field: "target_concept", headerName: "Target ID", hide: "false"},
                {field: "target_concept_display", headerName: "Target Concept"}, //, cellRenderer: this.itemsGridCellRenderer
                {field: "comments", headerName: "Comments"},
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

                    this.overviewItemsGridOptions.column_definitions = search_results.column_definitions;

                    $.each(search_results.column_definitions, function(index, column){

                        this.overviewItemsGridOptions.columnDefs.push({field: column.name, headerName: column.label_display, cellRenderer: this.itemsGridCellRenderer});
                    }.bind(this));

                    this.overviewItemsGridOptions.api.setColumnDefs(this.overviewItemsGridOptions.columnDefs);

                    params.successCallback(search_results.data, search_results.total_number);

                    //$("#komet_mapping_overview_items_" + this.viewerID).find(".komet-mapping-set-editor-edit").hide();
                    UIHelper.toggleFieldAvailability($("#komet_mapping_overview_items_" + this.viewerID).find(".komet-mapping-set-editor-edit"), false);
                }.bind(this));
            }.bind(this)
        };

        this.overviewItemsGridOptions.api.setDatasource(dataSource);

        // reload the recents menu
        //loadAssemblageRecents();
    };

    MappingViewer.prototype.onOverviewItemsGridSelection = function(event){

        // enable item specific actions
        UIHelper.toggleFieldAvailability("#komet_mapping_overview_item_delete_" + this.viewerID, true);
        UIHelper.toggleFieldAvailability("#komet_mapping_overview_item_edit_" + this.viewerID, true);
        UIHelper.toggleFieldAvailability("#komet_mapping_overview_item_comment_" + this.viewerID, true);

        var rowNumber = this.overviewItemsGridOptions.api.getSelectedNodes()[0].id;
        var grid = $("#komet_mapping_overview_items_" + this.viewerID);
        var editRow = grid.find("div.komet-grid-editing");

        if (editRow.length > 0 && editRow.attr("row") != rowNumber){

            //editRow.find(".komet-mapping-set-editor-display").show();
            UIHelper.toggleFieldAvailability(editRow.find(".komet-mapping-set-editor-edit"), false);
            editRow.removeClass("komet-grid-editing");

            var selectedRow = grid.find("div[row='" + rowNumber + "'].ag-row");


        }

        //selectedRows.forEach(function (selectedRow, index) {});
    }.bind(this);

    MappingViewer.prototype.onOverviewItemsGridDoubleClick = function(){

       // var selectedRows = this.overviewItemsGridOptions.api.getSelectedRows();
        var rowNumber = this.overviewItemsGridOptions.api.getSelectedNodes()[0].id;

       // selectedRows.forEach(function (selectedRow, index) {

            var row = $("#komet_mapping_overview_items_" + this.viewerID).find("div[row='" + rowNumber + "'].ag-row");
            row.addClass("komet-grid-editing");
            UIHelper.toggleFieldAvailability(row.find(".komet-mapping-set-editor-edit"), true);
            //row.find(".komet-mapping-set-editor-edit").show();
            //row.find(".komet-mapping-set-editor-display").hide();

           // console.log("Editing map item " + selectedRow.id);
       // }.bind(this));
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

        $(".komet-mapping-set-editor-display:not(.komet-mapping-set-editor-create-only)").hide();
        $(".komet-mapping-set-editor-edit:not(.komet-mapping-set-editor-create-only)").show();

        this.setEditorMapSetCopy = jQuery.extend({}, this.setEditorMapSet);
    };

    MappingViewer.prototype.cancelSetEditMode = function(previousSetID){

        if (this.viewerAction == MappingModule.CREATE_SET){

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

        if (this.setEditorMapSetCopy != null){

            this.setEditorMapSet = jQuery.extend({}, this.setEditorMapSetCopy);
            this.setEditorMapSetCopy = null;
        }

        if (this.setEditorOriginalIncludedFields != null){

            $("#" + this.SET_INCLUDE_FIELD_CHECKBOX_SECTION).html(document.createRange().createContextualFragment(this.setEditorOriginalIncludedFields));
            this.generateSetEditorAdditionalFields();
            $("#komet_mapping_set_definition_tab_" + this.viewerID).find(".komet-mapping-set-added-row .komet-mapping-set-editor-edit").hide();
        }

        if (this.setEditorOriginalItemsIncludedFields != null){

            $("#" + this.ITEMS_INCLUDE_FIELD_CHECKBOX_SECTION).html(document.createRange().createContextualFragment(this.setEditorOriginalItemsIncludedFields));
            this.generateSetEditorItemsAdditionalFields();
        }
    };

    MappingViewer.prototype.addItem = function() {

        this.overviewItemsGridOptions.api.addItems([{}]);
    };

    MappingViewer.prototype.enterItemEditMode = function(){

    };


   /* var thisViewer = this;

    // function to act as a class
    function MyCellEditor () {}

    // gets called once before the renderer is used
    MyCellEditor.prototype.init = function(params) {
        // create the cell
        this.eInput = document.createElement('input');
        this.eInput.value = params.value;

        var fieldInfo = thisViewer.overviewItemsGridOptions.column_definitions[params.colDef.field];

        var idPrefix = "komet_mapping_set_editor_item_";
        var name = 'name="' + idPrefix + fieldInfo.name+ ' ';
        var id = 'id="' + idPrefix + fieldInfo.name + '_' + thisViewer.viewerID + ' ';
        var classes = "form-control komet-mapping-set-editor-edit";
        var value = params.value;
        var dataType = fieldInfo.data_type;
        var cellContents = "";

        if (dataType == "UUID"){

            var displayValue = "";

            if (params.data[fieldInfo.name + "_display"] != undefined){
                displayValue = params.data[fieldInfo.name + "_display"];
            }

            cellContents += '<autosuggest '
                + 'id-base="' + idPrefix + fieldInfo.name + '" '
                + 'id-postfix="_' + thisViewer.viewerID + '" '
                + 'value="' + value + '" '
                + 'display-value="' + displayValue + '" '
                + 'classes="komet-mapping-set-editor-edit" '
                + '></autosuggest>';

            value = displayValue;

        } else if (dataType == "BOOLEAN"){

            cellContents += UIHelper.createSelectFieldString(id, name, classes, UIHelper.getPreDefinedOptionsForSelect("true_false"), value);
        } else {
            cellContents += '<input ' + name + id + 'class="' + classes + '" value="' + value + '">';
        }

        this.cellContents = cellContents;

    };

    // gets called once when grid ready to insert the element
    MyCellEditor.prototype.getGui = function() {
        return this.eInput;
    };

    // focus and select can be done after the gui is attached
    MyCellEditor.prototype.afterGuiAttached = function() {
        this.eInput.focus();
        this.eInput.select();
    };

    // returns the new value after editing
    MyCellEditor.prototype.getValue = function() {
        return this.eInput.value;
    };

    // any cleanup we need to be done here
    MyCellEditor.prototype.destroy = function() {
        // but this example is simple, no cleanup, we could
        // even leave this method out as it's optional
    };

    // if true, then this editor will appear in a popup
    MyCellEditor.prototype.isPopup = function() {
        //and we could leave this method out also, false is the default
        return false;
    };*/


    // call our constructor function
    this.init(viewerID, currentSetID, viewerAction)
};
