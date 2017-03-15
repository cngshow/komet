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
        this.showOverviewInactiveConcepts = null;
        this.showSTAMP = true;
        this.viewerAction = viewerAction;
        this.setEditorMapSet = {};
        this.INCLUDE_FIELD_CLASS_PREFIX = "komet-mapping-added-";
        this.SET_INCLUDE_FIELD_PREFIX = "komet_mapping_set_editor_include_fields_";
        this.SET_INCLUDE_FIELD_CHECKBOX_SECTION = "komet_mapping_set_editor_select_included_fields_" + viewerID;
        this.SET_INCLUDE_FIELD_DIALOG = "komet_mapping_set_editor_add_set_fields_" + viewerID;
        this.ITEMS_INCLUDE_FIELD_TEMPLATES = "komet_mapping_set_editor_items_add_fields_template_" + viewerID;
        this.ITEMS_INCLUDE_FIELD_PREFIX = "komet_mapping_set_editor_items_include_fields_";
        this.ITEMS_INCLUDE_FIELD_CHECKBOX_SECTION = "komet_mapping_set_editor_items_select_included_fields_" + viewerID;
        this.ITEMS_INCLUDE_FIELD_DIALOG = "komet_mapping_set_editor_items_add_set_fields_" + viewerID;
        this.SET_EDITOR_FORM = "komet_mapping_set_editor_form_" + viewerID;
        this.LINKED_TEXT = "Viewer linked to Mapping Tree. Click to unlink.";
        this.UNLINKED_TEXT = "Viewer not linked to Mapping Tree. Click to link.";
    };

    MappingViewer.prototype.getStampDate = function(){

        var stamp_date = $("#komet_mapping_stamp_date_" + this.viewerID).find("input").val();

        if (stamp_date == '' || stamp_date == 'latest') {
            return 'latest';
        } else {
            return new Date(stamp_date).getTime().toString();
        }
    };

    MappingViewer.prototype.getAllowedStates = function(){
        return $("#komet_mapping_allowed_states_" + this.viewerID).val();
    };

    MappingViewer.prototype.getStampModules = function(){
        return $('#komet_mapping_stamp_module_' + this.viewerID).val();
    };

    MappingViewer.prototype.getStampPath = function(){
        return $('#komet_mapping_stamp_path_' + this.viewerID).val();
    };

    // function to set the initial state of the view param fields when the viewer content changes
    MappingViewer.prototype.initViewParams = function(view_params) {

        // initialize the STAMP date field
        UIHelper.initDatePicker("#komet_mapping_stamp_date_" + this.viewerID, view_params.time);
    };

    MappingViewer.prototype.reloadViewer = function() {
        MappingModule.callLoadViewerData(this.currentSetID, this.getViewParams(), this.viewerAction, this.viewerID);
    };

    MappingViewer.prototype.getViewParams = function(){
        return {time: this.getStampDate(), allowedStates: this.getAllowedStates(), modules: this.getStampModules(), path: this.getStampPath()};
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

            if (!state) {
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

        Common.cursor_wait();

        // TODO - figure out how to stop having tab navigate through the grid, takes forever to get out of it
        $("#komet_mapping_overview_sets_tab_trigger_" + this.viewerID).focus(function(){

            if (this.overviewSetsGridOptions && this.overviewSetsGridOptions.api.rowModel.rowsToDisplay.length > 0){

                this.overviewSetsGridOptions.api.ensureIndexVisible(0);
                this.overviewSetsGridOptions.api.setFocusedCell(0, "name");
            }
        }.bind(this));

        // If a grid already exists destroy it or it will create a second grid
        if (this.overviewSetsGridOptions) {
            this.overviewSetsGridOptions.api.destroy();
        }

        // disable map set specific actions
        this.setOverviewSetsGridActions(null);

        // set the options for the result grid
        this.overviewSetsGridOptions = {
            enableColResize: true,
            enableSorting: true,
            suppressCellSelection: false,
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
        this.overviewSetsGridOptions.paginationPageSize = pageSize;

        // set the grid datasource options, including processing the data rows
        var dataSource = {

            getRows: function (params) {

                var pageNumber = params.endRow / pageSize;

                searchParams += "&overview_sets_page_number=" + pageNumber + "&" + jQuery.param({view_params: this.getViewParams()});

                // make an ajax call to get the data
                $.get(gon.routes.mapping_get_overview_sets_results_path + searchParams, function (search_results) {

                    params.successCallback(search_results.data, search_results.total_number);
                    Common.cursor_auto();
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

        var editParent = null;
        if (RolesModule.can_edit_concept()) {
            editParent = $("#komet_mapping_overview_set_edit_" + this.viewerID).parent(); //EDIT
        }
        var stateIcon = $("#komet_mapping_overview_set_state_" + this.viewerID);
        var stateParent = stateIcon.parent();

        if (selectedRow != null) {
            if (RolesModule.can_edit_concept()) {
                UIHelper.toggleFieldAvailability(editParent, true);//EDIT
            }
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
            if (RolesModule.can_edit_concept()) {
                UIHelper.toggleFieldAvailability(editParent, false);//EDIT
            }
        }
    };

    MappingViewer.prototype.loadOverviewSetsGridSelectedSet = function(action){

        var selectedRows = this.overviewSetsGridOptions.api.getSelectedRows();

        selectedRows.forEach(function (selectedRow) {
            $.publish(KometChannels.Mapping.mappingTreeNodeSelectedChannel, [null, selectedRow.set_id, this.getViewParams(), this.viewerID, WindowManager.INLINE, action]);
        }.bind(this));
    };

    MappingViewer.prototype.toggleSTAMP = function(){

        this.showSTAMP = $("#komet_mapping_show_stamp_" + this.viewerID)[0].checked;

        if (this.viewerAction == MappingModule.SET_LIST) {

            this.overviewSetsGridOptions.columnApi.setColumnsVisible(["state", "time", "author", "module", "path"], this.showSTAMP);
            this.overviewSetsGridOptions.api.sizeColumnsToFit();
        } else {
            $("#komet_mapping_section_" + this.viewerID).find(".komet-mapping-stamp-fields").toggleClass("hide", !this.showSTAMP);
        }
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

    MappingViewer.prototype.initializeSetEditor = function(viewerAction, mapItems){

        var form = $("#komet_mapping_set_editor_form_" + this.viewerID);

        $("#komet_viewer_" + this.viewerID).on( 'unsavedCheck', function(event){

            var changed = UIHelper.hasFormChanged(form, false, false);
            var shouldStay = false

            if (changed){
                shouldStay = !confirm("You have unsaved changes. Are you sure you want to leave this page?");
            }

            return shouldStay;
        });

        var thisViewer = this;

        this.viewerAction = viewerAction;
        this.setEditorOriginalIncludedFields = null;
        this.setEditorOriginalItemsIncludedFields = null;
        this.setEditorMapItemsCopy = null;

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

        var itemTemplatesOptions = '';

        $.each(this.setEditorMapSet.item_templates, function(key, value){
            itemTemplatesOptions += '<option>' + key + '</option>'
        });

        $("#" + this.ITEMS_INCLUDE_FIELD_TEMPLATES).append(itemTemplatesOptions);

        var itemsDialogRightColumn = $('#' + this.ITEMS_INCLUDE_FIELD_DIALOG).find(".komet-add-fields-dialog-right-column");

        var calculatedFieldsSelection = '<div class="komet-add-fields-dialog-body-header"><label for="komet_mapping_set_editor_items_add_fields_calculated_field_' + this.viewerID + '">Add From Calculated Fields</label></div>'
            + '<div><select id="komet_mapping_set_editor_items_add_fields_calculated_field_' + this.viewerID + '" class="form-control"><option value="" selected></option>';

        for (var i = 0; i < this.setEditorMapSet["all_calculated_fields"].length; i++){
            
            var field_info = this.setEditorMapSet["all_calculated_fields"][i];
            calculatedFieldsSelection += '<option data-component-type="' + field_info.component_type + '" value="' + field_info.id + '">' + field_info.text + '</option>';
        }

        calculatedFieldsSelection += '</select></div><div><button type="button" class="btn btn-default" aria-label="Add Calculated field" onclick="WindowManager.viewers[' + this.viewerID + '].addSetItemsCalculatedField();">Add Field</button></div>'
            + '<br><div class="komet-add-fields-dialog-body-header">OR</div><br>';

        itemsDialogRightColumn.prepend(calculatedFieldsSelection);

        if (this.viewerAction != MappingModule.CREATE_SET){

            var itemGrid = $("#komet_mapping_items_" + this.viewerID);
            this.itemFieldInfo = mapItems.column_definitions;

            var itemSectionString = "";

            if (mapItems.data.length == 0){
                itemSectionString += this.createItemNoDataRowString();
            } else {

                for (var i = 0; i < mapItems.data.length; i++){
                    itemSectionString += this.createItemRowString(mapItems.data[i]);
                }
            }

            // create a dom fragment from our items structure
            var itemSection = document.createRange().createContextualFragment(itemSectionString);
            itemGrid.append(itemSection);

            UIHelper.processAutoSuggestTags(itemGrid);
        }

        if (this.viewerAction == MappingModule.SET_DETAILS){
            form.find(".komet-mapping-show-on-edit").hide();
        } else {
            form.find(".komet-mapping-show-on-view").hide();
        }

        $("#komet_mapping_set_tabs_" + this.viewerID).tabs();

        form.submit(function () {

            UIHelper.removePageMessages(form);
            Common.cursor_wait();

            $.ajax({
                type: "POST",
                url: $(this).attr("action"),
                data: $(this).serialize(), //new FormData($(this)[0]),
                error: function(){Common.cursor_auto();},
                success: function (data) {

                    var setSection = $("#komet_mapping_set_panel_" + thisViewer.viewerID);
                    var itemSection = $("#komet_mapping_items_section_" + thisViewer.viewerID);

                    if (data.failed.set.length == 0){
                        MappingModule.tree.reloadTree(thisViewer.getViewParams());
                    }

                    if (data.failed.set.length > 0 || data.failed.items.length > 0){

                        var topErrorMessage = "Errors occurred with ";

                        if (data.failed.set.length > 0){

                            topErrorMessage += "the map set";
                            setSection.prepend(UIHelper.generatePageMessage(data.failed.set[0].error));

                            if (data.failed.items.length > 0){
                                topErrorMessage += " and with ";
                            }
                        }

                        if (data.failed.items.length > 0){
                            topErrorMessage += "map items";
                        }

                        setSection.before(UIHelper.generatePageMessage(topErrorMessage + ". All changes not listed were processed. See below for the errors."));

                        for (var i = 0; i < data.failed.items.length; i++) {

                            itemSection.find("#komet_mapping_item_row_" + data.failed.items[i].id + "_" + thisViewer.viewerID).before(UIHelper.generatePageMessage(data.failed.items[i].error));
                        }

                        Common.cursor_auto();

                    } else {

                        $("#komet_viewer_" + viewerID).off('unsavedCheck');
                        setSection.before(UIHelper.generatePageMessage("All changes were processed successfully.", true, "success"));
                        MappingModule.setTreeViewParams(thisViewer.getViewParams());
                        $.publish(KometChannels.Mapping.mappingTreeNodeSelectedChannel, ["", data.set_id, thisViewer.getViewParams(), thisViewer.viewerID, WindowManager.INLINE, MappingModule.SET_DETAILS]);
                    }
                }
            });

            // have to return false to stop the form from posting twice.
            return false;
        });

    };

    MappingViewer.prototype.validateEditForm = function(){

        var form = $("#komet_mapping_set_editor_form_" + this.viewerID);
        UIHelper.removePageMessages(form);

        var name = $("#komet_mapping_set_editor_name_" + this.viewerID);
        var description = $("#komet_mapping_set_editor_description_" + this.viewerID);
        var hasErrors = false;

        if (name.val() == undefined || name.val() == ""){

            name.before(UIHelper.generatePageMessage("The Name field must be filled in."));
            hasErrors = true;
        }

        if (description.val() == undefined || description.val() == ""){

            description.before(UIHelper.generatePageMessage("The Purpose field must be filled in."));
            hasErrors = true;
        }

        if (hasErrors){

            $("#komet_mapping_set_panel_" + this.viewerID).prepend(UIHelper.generatePageMessage("Please fix the errors below."));
            return false;
        }

        form.submit();
    };

    /********* Map Set Additional Fields Methods *****/

    MappingViewer.prototype.generateSetEditorDialogIncludeSection = function(fieldID, fieldInfo){

        var sectionString = '<div role="group" aria-labelledby="' + this.SET_INCLUDE_FIELD_PREFIX + fieldID + '_field_label' + this.viewerID + '" class="' + this.INCLUDE_FIELD_CLASS_PREFIX + fieldID + '">'
            + '<input type="checkbox" name="' + this.SET_INCLUDE_FIELD_PREFIX.slice(0, -1) + '[]" class="form-control" '
            + 'id="' + this.SET_INCLUDE_FIELD_PREFIX + fieldID + '_' + this.viewerID + '" value="' + fieldID + '" title="Show Field" aria-label="Show ' + fieldInfo.text + ' Field" ';

        if (fieldInfo.display){
            sectionString += 'checked="checked"';
        }

        sectionString += '><label id="' + this.SET_INCLUDE_FIELD_PREFIX + fieldID + '_field_label' + this.viewerID + '" for="' + this.SET_INCLUDE_FIELD_PREFIX + fieldID + '_' + this.viewerID + '">' + fieldInfo.text + '</label>';

        if (fieldInfo.removable){
            sectionString += '<button type="button" class="komet-link-button komet-flex-right" onclick="WindowManager.viewers[' + this.viewerID + '].removeSetIncludedField(\'' + fieldID + '\');" title="Remove Field" aria-label="Remove ' + fieldInfo.text + ' Field">'
                + '<div class="glyphicon glyphicon-remove"></div></button>';
        }

        sectionString += '<input type="hidden" name="' + this.SET_INCLUDE_FIELD_PREFIX + fieldID + '_label" value="' + fieldInfo.id + '">'
            + '<input type="hidden" name="' + this.SET_INCLUDE_FIELD_PREFIX + fieldID + '_data_type" value="' + fieldInfo.data_type + '">'
            + '<input type="hidden" name="' + this.SET_INCLUDE_FIELD_PREFIX + fieldID + '_required" value="' + fieldInfo.required + '">'
            + '<input type="hidden" name="' + this.SET_INCLUDE_FIELD_PREFIX + fieldID + '_removable" value="' + fieldInfo.removable + '">'
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
            var classes = "form-control komet-mapping-show-on-edit";
            var value = "";
            var dataType = "STRING";
            var labelValue = fieldsToInclude[i];
            var labelDisplayValue = fieldsToInclude[i];
            var required = false;

            if (this.setEditorMapSet[fieldsToInclude[i]] != undefined){

                value = this.setEditorMapSet[fieldsToInclude[i]].value;
                dataType = this.setEditorMapSet[fieldsToInclude[i]].data_type;
                labelValue = value;
                labelDisplayValue = this.setEditorMapSet[fieldsToInclude[i]].text;
                required = this.setEditorMapSet[fieldsToInclude[i]].required;
            }

            var label = '<label for="' + idPrefix + fieldsToInclude[i] + '_' + this.viewerID + '">' + labelDisplayValue + ':</label>';

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
                    + 'classes="' + classes + '" '
                    + '></autosuggest>';

                value = displayValue;

            } else if (dataType == "BOOLEAN"){
                includedFields += label + UIHelper.createSelectFieldString(id, name, classes, UIHelper.getPreDefinedOptionsForSelect("true_false"), value);
            } else {
                includedFields += label + '<input name="' + name + '" id="' + id + '" class="' + classes + '" value="' + value + '">';
            }

            includedFields += '<div class="komet-mapping-show-on-view">' + value + '</div>';

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
        var includeSection = $("#" + this.SET_INCLUDE_FIELD_CHECKBOX_SECTION);
        dialog.removeClass("hide");
        dialog.position({my: "right top", at: "right bottom", of: "#komet_mapping_set_editor_save_" + this.viewerID});

        if (this.setEditorOriginalIncludedFields == null) {

            this.setEditorOriginalIncludedFields = includeSection.html();
        }

        // set the focus onto the dialog for accessibility
        dialog.find("input:first")[0].focus();

        // copy the include section and mapset javascript object so we can return them to this state if the user cancels the dialog
        this.setEditorSetIncludeSectionCopy = includeSection.html();
        this.setEditorMapSetCopy = jQuery.extend(true, {}, this.setEditorMapSet);
    };

    MappingViewer.prototype.cancelIncludeSetFieldsDialog = function(){

        $('#' + this.SET_INCLUDE_FIELD_DIALOG).addClass("hide");

        // use the copy of the include section and mapset javascript object to return them to their prior state
        $("#" + this.SET_INCLUDE_FIELD_CHECKBOX_SECTION).html(this.setEditorSetIncludeSectionCopy);
        this.setEditorMapSet = jQuery.extend({}, this.setEditorMapSetCopy);
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
        $("#komet_mapping_set_editor_form_" + this.viewerID).find(".komet-mapping-show-on-view").hide();
    };

    MappingViewer.prototype.removeSetIncludedField = function(fieldName){

        // remove the field section from the dialog included fields
        $("#" + this.SET_INCLUDE_FIELD_CHECKBOX_SECTION).find($("." + this.INCLUDE_FIELD_CLASS_PREFIX + fieldName)).remove();

        // remove the field information from the map set info javascript variable, both the field information and from the include fields array
        this.setEditorMapSet["include_fields"].splice(this.setEditorMapSet["include_fields"].indexOf(fieldName), 1);
        delete this.setEditorMapSet[fieldName];
    };

    MappingViewer.prototype.addSetField = function(){

        var dialog = $("#" + this.SET_INCLUDE_FIELD_DIALOG);
        UIHelper.removePageMessages(dialog);

        var prefix = "#komet_mapping_set_editor_add_fields_";
        var dataTypeField = $(prefix + "data_type_" + this.viewerID);
        var labelField = $(prefix + "label_" + this.viewerID);
        var labelDisplayField = $(prefix + "label_display_" + this.viewerID);
        var requiredField = $(prefix + "required_" + this.viewerID);

        if (dataTypeField.val() == "" || labelField.val() == ""){

            dialog.find(".komet-add-fields-dialog-right-column").prepend(UIHelper.generatePageMessage("The field was not added. All fields below must be filled in to add a field."));
            return;
        }

        // make sure there are no invalid characters in the id
        // var id = labelDisplayField.val().replace(/[^a-zA-Z0-9_\-]/g, '').toLowerCase();
        var id = labelField.val();

        if (this.setEditorMapSet.include_fields.indexOf(id) >= 0){

            dialog.find(".komet-add-fields-dialog-right-column").prepend(UIHelper.generatePageMessage("The field was not added. The label must be unique. There is another field in this mapset with this label."));
            return;
        }

        var fieldInfo = {"id": id,
            "data_type": dataTypeField.val(),
            "text": labelDisplayField.val().replace(/[^a-zA-Z0-9_,\- ]+/g, ''),
            "required": requiredField[0].checked,
            "value": "",
            "removable": true,
            "display": true
        };

        this.setEditorMapSet.include_fields.push(id);
        this.setEditorMapSet[id] = fieldInfo;

        var newSection = this.generateSetEditorDialogIncludeSection(id, fieldInfo);

        // create a dom fragment from our generated structure and append it to the dialog form
        $("#" + this.SET_INCLUDE_FIELD_CHECKBOX_SECTION).append(document.createRange().createContextualFragment(newSection));

        dataTypeField.val("STRING");
        labelField.val("");
        labelDisplayField.val("");
        requiredField[0].checked = false;
    };

    /********* Set Item Additional Fields Methods */

    MappingViewer.prototype.generateSetEditorItemsDialogIncludeSection = function(fieldID, fieldInfo){

        var fieldSection = this.ITEMS_INCLUDE_FIELD_PREFIX + 'section_' + fieldID + '_' + this.viewerID;
        var formFieldID = fieldID;// + '_' + fieldInfo.component_type;

        var sectionString = '<div class="' + this.INCLUDE_FIELD_CLASS_PREFIX + formFieldID + '" id="' + fieldSection + '">'
            + '<button type="button" class="komet-link-button" onclick="WindowManager.viewers[' + this.viewerID + '].changeFieldOrder(\'' + fieldSection + '\', \'up\');" title="Move Field Order Up" aria-label="Move ' + fieldInfo.text + ' Field Order Up"><div class="glyphicon glyphicon-arrow-up komet-mapping-change-order-icon"></div></button> '
            + '<button type="button" class="komet-link-button" onclick="WindowManager.viewers[' + this.viewerID + '].changeFieldOrder(\'' + fieldSection + '\', \'down\');" title="Move Field Order Down" aria-label="Move ' + fieldInfo.text + ' Field Order Down"><div class="glyphicon glyphicon-arrow-down komet-mapping-change-order-icon"></div></button> '
            + '<input type="checkbox" name="' + this.ITEMS_INCLUDE_FIELD_PREFIX.slice(0, -1) + '[]" class="form-control" '
            + 'id="' + this.ITEMS_INCLUDE_FIELD_PREFIX + formFieldID + '_' + this.viewerID + '" value="' + fieldID + '" title="Show Field" aria-label="Show ' + fieldInfo.text + ' Field" ';

        if (fieldInfo.display){
            sectionString += 'checked="checked"';
        }

        sectionString += '><label for="' + this.ITEMS_INCLUDE_FIELD_PREFIX + formFieldID + '_' + this.viewerID + '">' + fieldInfo.text + '</label>';

        if (fieldInfo.removable){
            sectionString += '<button type="button" class="komet-link-button komet-flex-right" onclick="WindowManager.viewers[' + this.viewerID + '].removeSetItemsIncludedField(\'' + formFieldID + '\');" title="Remove Field" aria-label="Remove ' + fieldInfo.text + ' Field">'
                + '<div class="glyphicon glyphicon-remove"></div></button>';
        }

        sectionString += '<input type="hidden" name="' + this.ITEMS_INCLUDE_FIELD_PREFIX + formFieldID + '_label" value="' + fieldInfo.id + '">'
            + '<input type="hidden" name="' + this.ITEMS_INCLUDE_FIELD_PREFIX + formFieldID + '_data_type" value="' + fieldInfo.data_type + '">'
            + '<input type="hidden" name="' + this.ITEMS_INCLUDE_FIELD_PREFIX + formFieldID + '_component_type" value="' + fieldInfo.component_type + '">'
            + '<input type="hidden" name="' + this.SET_INCLUDE_FIELD_PREFIX + formFieldID + '_required" value="' + fieldInfo.required + '">'
            + '<input type="hidden" name="' + this.ITEMS_INCLUDE_FIELD_PREFIX + formFieldID + '_removable" value="' + fieldInfo.removable + '">'
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

            //var idPrefix = "komet_mapping_set_editor_items_";
            //var name = 'name="' + idPrefix + fieldsToInclude[i]+ ' ';
            //var id = 'id="' + idPrefix + fieldsToInclude[i] + '_' + this.viewerID + ' ';
            var dataType = "STRING";
            var componentType = "";
            //var labelValue = fieldsToInclude[i];
            var labelDisplayValue = fieldsToInclude[i];
            var required = false;

            if (fieldInfo != undefined){

                dataType = fieldInfo.data_type;
                componentType = fieldInfo.component_type;
                //labelValue = fieldInfo.id;
                labelDisplayValue = fieldInfo.text;
                required = fieldInfo.required;
            }

            includedFields += '<div><b>Name:</b> ' + labelDisplayValue + '</div>';
            includedFields += '<div><b>Data Type:</b> ' + dataType + '</div>';

            if (dataType == "SELECT" && componentType != "EQUIVALENCE_TYPE"){

                includedFields += '<div><b>Options:</b> ';

                for (var i = 0; i < fieldInfo.options.length; i++){

                    if (i > 0){
                        includedFields += ',';
                    }

                    includedFields += ' ' + fieldInfo.options[i].label;
                }

                includedFields += '</div>';
            }

            includedFields += '<div><b>Required:</b> ' + required + '</div>';

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
        var includeSection = $("#" + this.ITEMS_INCLUDE_FIELD_CHECKBOX_SECTION);
        dialog.removeClass("hide");
        dialog.position({my: "right top", at: "right bottom", of: "#komet_mapping_set_editor_save_" + this.viewerID});

        if (this.setEditorOriginalItemsIncludedFields == null) {

            this.setEditorOriginalItemsIncludedFields = includeSection.html();
        }

        // set the focus onto the dialog for accessibility
        dialog.find("select:first")[0].focus();

        // copy the include section and mapset javascript object so we can return them to this state if the user cancels the dialog
        this.setEditorItemIncludeSectionCopy = includeSection.html();
        this.setEditorMapSetCopy = jQuery.extend(true, {}, this.setEditorMapSet);
    };

    MappingViewer.prototype.cancelIncludeSetItemsFieldsDialog = function(){

        $('#' + this.ITEMS_INCLUDE_FIELD_DIALOG).addClass("hide");

        // use the copy of the include section and mapset javascript object to return them to their prior state
        $("#" + this.ITEMS_INCLUDE_FIELD_CHECKBOX_SECTION).html(this.setEditorItemIncludeSectionCopy);
        this.setEditorMapSet = jQuery.extend({}, this.setEditorMapSetCopy);
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

    MappingViewer.prototype.changeFieldOrder = function(fieldSection, direction) {

        var selected = $("#" + fieldSection);
        var target;

        // if we are moving the selected field up the target is the previous sibling, otherwise it's the next sibling
        if (direction == "up") {
            target = selected.prev();
        } else {
            target = selected.next();
        }

        // make sure the target exists
        if (target.length) {

            // if we are moving the selected field up the move the target to after the selected field, otherwise move it to before the selected field
            if (direction == "up") {
                selected.after(target);
            } else {
                selected.before(target);
            }
        }
    };

    MappingViewer.prototype.removeSetItemsIncludedField = function(fieldName){

        // remove the field section from the dialog included fields
        $("#" + this.ITEMS_INCLUDE_FIELD_CHECKBOX_SECTION).find($("." + this.INCLUDE_FIELD_CLASS_PREFIX + fieldName)).remove();

        // remove the field information from the map set info javascript variable, both the field information and from the include fields array
        this.setEditorMapSet["item_fields"].splice(this.setEditorMapSet["item_fields"].indexOf(fieldName), 1);
        delete this.setEditorMapSet["item_field_" + fieldName];
    };

    MappingViewer.prototype.addSetItemsTemplate = function(){

        var dialog = $("#" + this.ITEMS_INCLUDE_FIELD_DIALOG);
        UIHelper.removePageMessages(dialog);

        var templateField = $("#" + this.ITEMS_INCLUDE_FIELD_TEMPLATES);

        if (templateField.val() == ""){

            dialog.find(".komet-add-fields-dialog-left-column").prepend(UIHelper.generatePageMessage("You must select a template to add."));
            return;
        }

        var template = this.setEditorMapSet.item_templates[templateField.val()];
        var includeItemFields = "";

        for (var i = 0; i < template.length; i++){

            var fieldID = template[i].id + "_" + template[i].component_type

            if (!this.setEditorMapSet.item_fields[fieldID]){

                this.setEditorMapSet.item_fields.push(fieldID);
                this.setEditorMapSet["item_field_" + fieldID] = template[i];

                includeItemFields += this.generateSetEditorItemsDialogIncludeSection(fieldID, template[i]);
            }
        }

        // create a dom fragment from our generated structure and append it to the dialog form
        $("#" + this.ITEMS_INCLUDE_FIELD_CHECKBOX_SECTION).append(document.createRange().createContextualFragment(includeItemFields));

        // reset the template field
        templateField.val("");
    };

    MappingViewer.prototype.addSetItemsCalculatedField = function(){

        UIHelper.removePageMessages("#" + this.ITEMS_INCLUDE_FIELD_DIALOG);

        var calculatedField = $("#komet_mapping_set_editor_items_add_fields_calculated_field_" + this.viewerID);

        var id = calculatedField.val();

        if (id == ""){

            calculatedField.after(UIHelper.generatePageMessage("A Calculated field must be selected."));
            return;
        }

        var selectedOption = calculatedField.find("option:selected");

        var fieldInfo = {"id": id,
            "data_type": 'STRING',
            "component_type": selectedOption.attr("data-component-type"),
            "text": selectedOption.text(),
            "required": false,
            "removable": true,
            "display": true
        };

        var fieldID = id + "_" + fieldInfo.component_type;

        this.setEditorMapSet.item_fields.push(fieldID);
        this.setEditorMapSet["item_field_" + fieldID] = fieldInfo;

        var newSection = this.generateSetEditorItemsDialogIncludeSection(fieldID, fieldInfo);

        // create a dom fragment from our generated structure and append it to the dialog form
        $("#" + this.ITEMS_INCLUDE_FIELD_CHECKBOX_SECTION).append(document.createRange().createContextualFragment(newSection));

        // reset the field
        calculatedField.val("");
    };

    MappingViewer.prototype.addSetItemsField = function(){

        var dialog = $("#" + this.ITEMS_INCLUDE_FIELD_DIALOG);
        UIHelper.removePageMessages(dialog);

        var prefix = "#komet_mapping_set_editor_items_add_fields_";
        var dataTypeField = $(prefix + "data_type_" + this.viewerID);
        var labelField = $(prefix + "label_" + this.viewerID);
        var labelDisplayField = $(prefix + "label_display_" + this.viewerID);
        var requiredField = $(prefix + "required_" + this.viewerID);

        if (dataTypeField.val() == "" || labelField.val() == ""){

            dialog.find(".komet-add-fields-dialog-right-column .komet-add-fields-dialog-body-header").filter(":last").prepend(UIHelper.generatePageMessage("The field was not added. All fields below must be filled in."));
            return;
        }

        // make sure there are no invalid characters in the id
        // var id = labelDisplayField.val().replace(/[^a-zA-Z0-9_\-]/g, '').toLowerCase();
        var id = labelField.val();
        var fieldID = id + "_ITEM_EXTENDED";

        if (this.setEditorMapSet.item_fields.indexOf(fieldID) >= 0){

            dialog.find(".komet-add-fields-dialog-right-column .komet-add-fields-dialog-body-header").filter(":last").prepend(UIHelper.generatePageMessage("The field was not added. The label must be unique. There is another field in this mapset with this label."));
            return;
        }

        var fieldInfo = {"id": id,
            "data_type": dataTypeField.val(),
            "component_type": 'ITEM_EXTENDED',
            "text": labelDisplayField.val().replace(/[^a-zA-Z0-9_,\- ]+/g, ''),
            "required": requiredField[0].checked,
            "removable": true,
            "display": true
        };

        this.setEditorMapSet.item_fields.push(fieldID);
        this.setEditorMapSet["item_field_" + fieldID] = fieldInfo;

        var newSection = this.generateSetEditorItemsDialogIncludeSection(fieldID, fieldInfo);

        // create a dom fragment from our generated structure and append it to the dialog form
        $("#" + this.ITEMS_INCLUDE_FIELD_CHECKBOX_SECTION).append(document.createRange().createContextualFragment(newSection));

        dataTypeField.val("STRING");
        labelField.val("");
        labelDisplayField.val("");
        requiredField[0].checked = false;
    };

    MappingViewer.prototype.createItemNoDataRowString = function () {
        return '<div id="komet_mapping_item_edit_no_data_row_' + this.viewerID + '" class="komet-mapping-item-edit-row"><div>There are no items for this map set.</div></div>';
    };

    MappingViewer.prototype.createItemRowString = function (rowData) {

        var itemID = "";
        var state = "";
        var time = "";
        var author = "";
        var module = "";
        var path = "";
        var commentID = "0";
        var comment = "";
        //var state = "";
        var isNew = false;
        var rowID = "";
        var rowString = null;
        var idPrefix = "komet_mapping_item_" + itemID;
        var ariaLabel = "Mapping Item ";
        var classes = "form-control komet-mapping-show-on-edit";

        if (rowData != null){

            itemID = rowData.item_id;
            rowID = 'komet_mapping_item_row_' + itemID + '_' + this.viewerID;
            idPrefix = "komet_mapping_item_" + itemID;
            state = rowData.state;
            time = rowData.time;
            author = rowData.author;
            module = rowData.module;
            path = rowData.path;
            commentID = rowData.comment_id;
            comment = rowData.comment;
            ariaLabel = rowData.item_name + " ";

            rowString = '<div id="' + rowID + '" class="komet-mapping-item-edit-row">';
        } else {

            isNew = true;
            itemID = window.performance.now().toString().replace(".", "");
            rowID = 'komet_mapping_item_row_' + itemID + '_' + this.viewerID;
            idPrefix = "komet_mapping_item_" + itemID;

            rowString = '<div id="' + rowID + '" class="komet-mapping-item-edit-row">';
        }

        $.each(this.itemFieldInfo, function (fieldID, field) {

            var name = 'items[' + itemID + '][' + field.id + ']';
            var id = idPrefix + "_" + field.id + '_' + this.viewerID;
            var value = "";
            var dataType = field.data_type;
            var componentType = field.component_type;
            var itemAriaLabel = ariaLabel + ' ' + field.text;

            if (!isNew && rowData[field.id] != undefined){
                value = rowData[field.id];
            }

            rowString += '<div>';

            var displayValue = value;

            if (!isNew && rowData[field.id + "_display"] != undefined) {
                displayValue = rowData[field.id + "_display"];
            }

            if (dataType == "UUID" || field.id == "DESCRIPTION_TARGET" || (field.id == "DESCRIPTION_SOURCE" && isNew)) {

                rowString += '<autosuggest '
                    + 'id-base="' + idPrefix + "_" + field.id + '" '
                    + 'id-postfix="_' + this.viewerID + '" '
                    + 'label="' + itemAriaLabel + '" '
                    + 'label-display="tooltip" '
                    + 'name="items[' + itemID + '][' + field.id + '" '
                    + 'name-format="array" '
                    + 'value="' + value + '" '
                    + 'display-value="' + displayValue + '" '
                    + 'classes="komet-mapping-show-on-edit" '
                    + '></autosuggest>';

            } else if ((field.id == "DESCRIPTION_SOURCE" && !isNew) || componentType == "SOURCE" || componentType == "TARGET"){
                rowString += '<div class="komet-mapping-show-on-edit" aria-label="' + itemAriaLabel + '">' + displayValue + '</div>';

            } else if (dataType == "BOOLEAN"){
                rowString += UIHelper.createSelectFieldString(id, name, classes, UIHelper.getPreDefinedOptionsForSelect("true_false"), value, itemAriaLabel);

            } else if (dataType == "SELECT"){

                var tooltip = false;

                if (field.options_tooltip){
                    tooltip = field.options_tooltip;
                }

                rowString += UIHelper.createSelectFieldString(id, name, classes, field.options, value, itemAriaLabel, false, tooltip);

            } else {
                rowString += '<input name="' + name + '" id="' + id + '" class="' + classes + '" value="' + value + '" aria-label="' + itemAriaLabel + '">';
            }

            rowString += '<div class="komet-mapping-show-on-view" aria-label="' + itemAriaLabel + '">' + displayValue + '</div></div>';

        }.bind(this));

        rowString += '<div class="komet-mapping-item-edit-row-comments"><input type="hidden" name="items[' + itemID + '][comment_id]" value="' + commentID + '">'
            + '<input type="hidden" id="komet_mapping_item_' + itemID + '_comment" name="items[' + itemID + '][comment]" value="' + comment + '">'
            + '<a href="#" title="Add/Edit comment" aria-label="' + ariaLabel + ' Comments" class="komet-mapping-show-on-edit" onclick="WindowManager.viewers[' + this.viewerID + '].editItemComments(\'' + itemID + '\', this);return false;">';

        if (comment == "") {
            rowString += "Add comment";
        } else {
            rowString +=  comment;
        }

        rowString += '</a><div class="komet-mapping-show-on-view" aria-label="' + ariaLabel + ' Comments">' + comment + '</div></div>'
            + '<div class="komet-mapping-stamp-fields">' + UIHelper.createSelectFieldString(idPrefix + '_state', 'items[' + itemID + '][state]', classes, UIHelper.getPreDefinedOptionsForSelect("active_inactive"), state, ariaLabel + ' Item State')
            + '<div class="komet-mapping-show-on-view" aria-label="' + ariaLabel + ' Item State">' + state + '</div></div>'
            + '<div class="komet-mapping-stamp-fields"><div aria-label="' + ariaLabel + ' Item Time">' + time + '</div></div>'
            + '<div class="komet-mapping-stamp-fields"><div aria-label="' + ariaLabel + ' Item Author">' + author + '</div></div>'
            + '<div class="komet-mapping-stamp-fields"><div aria-label="' + ariaLabel + ' Item Module">' + module + '</div></div>'
            + '<div class="komet-mapping-stamp-fields"><div aria-label="' + ariaLabel + ' Item Path">' + path + '</div></div>'
            + '<div class="komet-mapping-item-edit-row-tools">';

        if (isNew){
            rowString += '<button type="button" class="komet-link-button" onclick="WindowManager.viewers[' + this.viewerID + '].removeItemRow(\'' + rowID + '\', this)" title="Remove row" aria-label="Remove row"><div class="glyphicon glyphicon-remove"></div></button>';
        }

        rowString += '<!-- end edit-row-tools --></div><!-- end edit-row --></div>';

        return rowString;
    };

    MappingViewer.prototype.editItemComments = function (itemID, commentLink) {

        var comment = $("#komet_mapping_item_" + itemID + "_comment");

        var commentFieldString = '<textarea class="form-control" id="komet_mapping_item_edit_comment_' + this.viewerID + '" aria-label="Enter or edit comment" autofocus="true">' + comment.val() + '</textarea>';

        var confirmCallback = function(buttonClicked){

            if (buttonClicked != 'cancel') {

                var editComment = $("#komet_mapping_item_edit_comment_" + this.viewerID).val();
                comment.val(editComment);

                if (editComment == ""){
                    $(commentLink).html("Add comment");
                } else {
                    $(commentLink).html(editComment);
                }
            }

        }.bind(this);

        UIHelper.generateConfirmationDialog("Edit Item Comment", commentFieldString, confirmCallback, "Save", commentLink);
    };

    MappingViewer.prototype.addItemRow = function () {

        var section = $("#komet_mapping_items_" + this.viewerID);

        // generate the new row string and create a dom fragment it
        var rowString = this.createItemRowString(null);
        var row = document.createRange().createContextualFragment(rowString);

        section.append(row);
        UIHelper.processAutoSuggestTags(section);

        // if there is a "No Data" row, remove it.
        var noDataRow = $("#komet_mapping_item_edit_no_data_row_" + this.viewerID);

        if (noDataRow.length > 0){
            noDataRow.remove();
        }

    };

    MappingViewer.prototype.removeItemRow = function (rowID, closeElement) {

        var confirmCallback = function(buttonClicked){

            if (buttonClicked != 'cancel') {

                var row = $("#" + rowID);
                row.remove();

                // if there's only the header row left in the items section, display a "No Data" row
                var section = $("#komet_mapping_items_" + this.viewerID);

                if (section.find("> div").length <= 1){
                    section.append(this.createItemNoDataRowString());
                }
            }

        }.bind(this);

        UIHelper.generateConfirmationDialog("Delete Map Item?", "Are you sure you want to remove this map item?", confirmCallback, "Yes", closeElement);
    };

    MappingViewer.prototype.enterSetEditMode = function(){

        $(".komet-mapping-show-on-view").hide();
        $(".komet-mapping-show-on-edit:not(.komet-mapping-show-on-create-only)").show();

        // make a copy of the set so we can restore it if the user cancels changes
        this.setEditorMapSetCopy = jQuery.extend({}, this.setEditorMapSet);

        // make a copy of the items grid so we can restore it if the user cancels changes
        if (this.viewerAction != MappingModule.CREATE_SET){
            this.setEditorMapItemsCopy = $("#komet_mapping_items_" + this.viewerID).html();
        }
    };

    MappingViewer.prototype.cancelSetEditMode = function(triggerElement){


        var confirmCallback = function(buttonClicked){

            if (buttonClicked != 'cancel') {

                if (this.viewerAction == MappingModule.CREATE_SET){
                    WindowManager.cancelEditMode(this.viewerID.toString());
                } else {

                    var itemGrid = $("#komet_mapping_items_" + this.viewerID);

                    if (this.setEditorMapItemsCopy != null){
                        itemGrid.html(this.setEditorMapItemsCopy);
                    }
                }

                $(".komet-mapping-show-on-view").show();
                $(".komet-mapping-show-on-edit").hide();

                console.log("Had Changes: " + UIHelper.hasFormChanged("#komet_mapping_set_editor_form_" + this.viewerID));
                UIHelper.resetFormChanges("#komet_mapping_set_editor_form_" + this.viewerID);

                if (this.setEditorMapSetCopy != null){

                    this.setEditorMapSet = jQuery.extend({}, this.setEditorMapSetCopy);
                    this.setEditorMapSetCopy = null;
                }

                if (this.setEditorOriginalIncludedFields != null){

                    $("#" + this.SET_INCLUDE_FIELD_CHECKBOX_SECTION).html(document.createRange().createContextualFragment(this.setEditorOriginalIncludedFields));
                    this.generateSetEditorAdditionalFields();
                    $("#komet_mapping_set_definition_tab_" + this.viewerID).find(".komet-mapping-set-added-row .komet-mapping-show-on-edit").hide();
                }

                if (this.setEditorOriginalItemsIncludedFields != null){

                    $("#" + this.ITEMS_INCLUDE_FIELD_CHECKBOX_SECTION).html(document.createRange().createContextualFragment(this.setEditorOriginalItemsIncludedFields));
                    this.generateSetEditorItemsAdditionalFields();
                }
            }

        }.bind(this);

        UIHelper.generateConfirmationDialog("Cancel Edits?", "Are you sure you want to discard all unsaved changes?", confirmCallback, "Yes", triggerElement);

    };

    // call our constructor function
    this.init(viewerID, currentSetID, viewerAction)
};
