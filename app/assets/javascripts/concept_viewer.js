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

var ConceptViewer = function(viewerID, currentConceptID, viewerAction) {

    ConceptViewer.prototype.init = function(viewerID, currentConceptID, viewerAction) {

        this.viewerID = viewerID;
        this.viewerAction = viewerAction;
        this.currentConceptID = currentConceptID;
        this.panelStates = {};
        this.trees = {};
        this.PARENTS_TREE = "concept_lineage_parents_tree_" + viewerID;
        this.CHILDREN_TREE = "concept_lineage_children_tree_" + viewerID;
        this.refsetGridOptions;
        this.REFSET_GRID = "refsets_grid_" + viewerID;
        this.LINKED_TEXT = "Viewer linked to Taxonomy Tree. Click to unlink.";
        this.UNLINKED_TEXT = "Viewer not linked to Taxonomy Tree. Click to link.";
    };

    ConceptViewer.prototype.getStatedView = function(){
        return $('#komet_concept_stated_' + this.viewerID).prop("checked");
    };

    ConceptViewer.prototype.getStampDate = function(){

        var stamp_date = $("#komet_concept_stamp_date_" + this.viewerID).find("input").val();

        if (stamp_date == '' || stamp_date == 'latest') {
            return 'latest';
        } else {
            return new Date(stamp_date).getTime().toString();
        }
    };

    // function to set the initial state of the view param fields when the viewer content changes
    ConceptViewer.prototype.initViewParams = function(view_params) {

        // get the stated field group
        var stated = $("#komet_viewer_" + this.viewerID).find("input[name='komet_concept_stated_inferred']");

        // initialize the stated field
        UIHelper.initStatedField(stated, view_params.stated);

        // initialize the STAMP date field
        UIHelper.initDatePicker("#komet_concept_stamp_date_" + this.viewerID, view_params.time);

    };

    ConceptViewer.prototype.reloadViewer = function() {
        ConceptsModule.callLoadViewerData(this.currentConceptID, this.getViewParams(), ConceptsModule.VIEW, this.viewerID);
    };

    ConceptViewer.prototype.getViewParams = function(){
        return {stated: this.getStatedView(), time: this.getStampDate()};
    };

    ConceptViewer.prototype.togglePanelDetails = function(panelID, callback, preserveState) {

        // get the panel's expander icon, or all expander icons if this is the top level expander
        var expander = $("#" + panelID + " .glyphicon-plus-sign, #" + panelID + " .glyphicon-minus-sign");
        var drawer = $("#" + panelID + " .komet-concept-section-panel-details");
        var topLevelExpander = expander.parent().hasClass('komet-panel-tools-control');
        var open;
        var newText = "";
        var expanderParent;

        // if the user clicked on the top level concept expander, change the associated text label
        if (topLevelExpander) {

            var expanderText = expander[0].nextElementSibling;
            expanderParent = expander[0].parentElement;

            if (expanderText.innerHTML == "Expand All") {

                newText = "Collapse All";
                open = true;

            } else {

                newText = "Expand All";
                open = false;
            }

            expanderText.innerHTML = newText;
        } else {
            open = expander.hasClass("glyphicon-plus-sign");
        }

        // change the displayed expander icon and drawer visibility
        if (open) {

            expander.removeClass("glyphicon-plus-sign");
            expander.addClass("glyphicon-minus-sign");
            expander.parent().attr("title", "Collapse");
            drawer.show();

        } else {

            expander.removeClass("glyphicon-minus-sign");
            expander.addClass("glyphicon-plus-sign");
            expander.parent().attr("title", "Expand");
            drawer.hide();
        }

        // save state if needed, and if there is a callback run it, passing the panel ID, open state, and concept ID.
        if(topLevelExpander){

            expanderParent.title = newText;

            // if this is the top level loop through all saved panel states and run the callback if it has one
            for (var key in this.panelStates) {

                this.panelStates[key][0] = open;

                if (this.panelStates[key].length > 1 && this.panelStates[key][1]){
                    this.panelStates[key][1](key, open, this.currentConceptID);
                }
            }
        } else {

            // if we are preserving state set the current state of the panel into the object.
            if (preserveState) {
                this.setPanelState(panelID, open, callback);
            }

            // run the callback
            if (this.panelStates[panelID] !== undefined && this.panelStates[panelID].length > 1 && this.panelStates[panelID][1]) {
                this.panelStates[panelID][1](panelID, open, this.currentConceptID);
            }
        }
    };

    ConceptViewer.prototype.setPanelState = function(panelID, state, callback) {

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

    ConceptViewer.prototype.getPanelState = function(panelID) {

        if(!this.panelStates[panelID]) {
            return false;
        }

        return this.panelStates[panelID][0];
    };

    ConceptViewer.prototype.restorePanelStates = function() {

        for (var key in this.panelStates) {

            var state = this.panelStates[key][0];
            var callback = this.panelStates[key][1];

            if (state) {
                this.togglePanelDetails(key, callback);
            }
        }
    };

    ConceptViewer.prototype.loadLineageTrees = function(){

        var viewParams = this.getViewParams();

        if (this.trees.hasOwnProperty(this.PARENTS_TREE) && this.trees[this.PARENTS_TREE].tree.jstree(true)){

            this.trees[this.PARENTS_TREE].tree.jstree(true).destroy();
            this.trees[this.CHILDREN_TREE].tree.jstree(true).destroy();
        }

        this.trees[this.PARENTS_TREE] = new KometTaxonomyTree(this.PARENTS_TREE, viewParams, true, this.currentConceptID, false, this.viewerID);
        this.trees[this.CHILDREN_TREE] = new KometTaxonomyTree(this.CHILDREN_TREE, viewParams, false, this.currentConceptID, false, this.viewerID, false);

        this.trees[this.PARENTS_TREE].tree.bind('ready.jstree', function (event, data) {

            // should use data.instance._cnt, but never has count anymore
            if (data.instance._model.data["#"].children.length == 0) {

                this.trees[this.PARENTS_TREE].tree.html("<div class='komet-reverse-tree-node'>No Parents</div>");
                $("#concept_lineage_header_text_" + this.viewerID).html("No Parent");
            } else{
                $("#concept_lineage_header_text_" + this.viewerID).html(data.instance.get_node('ul > li:first').text);
            }
        }.bind(this));

        this.trees[this.CHILDREN_TREE].tree.bind('ready.jstree', function (event, data) {

            // should use data.instance._cnt, but never has count anymore
            if (data.instance._model.data["#"].children.length == 0) {
                this.trees[this.CHILDREN_TREE].tree.html("No Children");
            }
        }.bind(this));
    };

    ConceptViewer.prototype.toggleNestedTableRows = function(image, id){
        // TODO - Look into what happens when two rows have the same name (ex: Pediatex CT)
        // get reference to the block of nested rows
        var nestedRows = $("#komet_concept_table_nested_row_" + this.viewerID + "_" + id);

        // change the displayed image and nested rows visibility
        if (image.hasClass("glyphicon-arrow-right")){

            image.removeClass("glyphicon-arrow-right");
            image.addClass("glyphicon-arrow-down");
            nestedRows.show();
            image.parent().addClass("komet-concept-table-nested-indicator-open");

        } else {

            image.removeClass("glyphicon-arrow-down");
            image.addClass("glyphicon-arrow-right");
            nestedRows.hide();
            image.parent().removeClass("komet-concept-table-nested-indicator-open");
        }
    };

    // show this concept in the taxonomy tree
    ConceptViewer.prototype.showInTaxonomyTree = function() {

        TaxonomyModule.tree.findNodeInTree(
            this.currentConceptID,
            TaxonomyModule.getViewParams(),
            function (foundNodeId) {},
            true
        );
    };

    ConceptViewer.prototype.loadRefsetGrid = function() {

        // If a grid already exists destroy it or it will create a second grid
        if (this.refsetGridOptions) {
            this.refsetGridOptions.api.destroy();
        }

        // set the options for the result grid
        this.refsetGridOptions = {
            enableColResize: true,
            enableSorting: true,
            suppressCellSelection: false,
            rowSelection: "single",
            onGridReady: onGridReady,
            rowModelType: 'pagination'
        };

        function onGridReady(event) {
            event.api.sizeColumnsToFit();
        }

        var refsetGridDiv = $("#" + this.REFSET_GRID);

        new agGrid.Grid(refsetGridDiv.get(0), this.refsetGridOptions);
        this.getRefsetResultData();

        $("#komet_refsets_tab_trigger_" + this.viewerID).focus(function(){

            if (this.refsetGridOptions.api.rowModel.rowsToDisplay.length > 0){

                this.refsetGridOptions.api.ensureIndexVisible(0);
                this.refsetGridOptions.api.setFocusedCell(0, "state");
            }
        }.bind(this));
    };

    ConceptViewer.prototype.getRefsetResultData = function() {

        // load the parameters from the form to add to the query string sent in the ajax data call
        var refsetsParams = "?concept_id=" + this.currentConceptID + "&" + jQuery.param({view_params: this.getViewParams()});
        var pageSize = 25;
        this.refsetGridOptions.paginationPageSize = pageSize;

        function renderCell(params) {

            if (params.value != undefined) {
                var cell_display = "";
                var tooltip = "";
                var menu_attributes = "";

                //if this row has a display value, show that in place of the row data and put a tooltip on the cell to show the row data
                if (params.value.display === '') {
                    cell_display = params.value.data;
                    tooltip = '';
                }
                else {
                    cell_display = params.value.display;
                    tooltip = " title='" + params.value.data + "'";
                }

                if (['uuid', 'nid', 'sctid'].indexOf(params.colDef.data_type.toLowerCase) >= 0) {
                    menu_attributes = "data-menu-type='sememe' data-menu-uuid='" + params.value.data + "'";
                }
                else {
                    menu_attributes = "data-menu-type='value' data-menu-copy-value='" + cell_display + "'"
                }

                return '<div class="komet-concept-table-cell-content komet-context-menu" ' + menu_attributes + tooltip + ' >' + cell_display + ' </div>'
            }
        }

        // set the grid datasource options, including processing the data rows
        var dataSource = {

            getRows: function (params) {

                var pageNumber = params.endRow / pageSize;

                refsetsParams += "&taxonomy_refsets_page_number=" + pageNumber;

                // make an ajax call to get the data
                $.get(gon.routes.taxonomy_get_concept_refsets_path + refsetsParams, function (refsets_results) {

                    $.each(refsets_results.columns, function (index, value) {
                        value.cellRenderer = renderCell
                    });

                    this.refsetGridOptions.api.setColumnDefs(refsets_results.columns);
                    params.successCallback(refsets_results.data, refsets_results.total_number);
                }.bind(this));
            }.bind(this)
        };

        this.refsetGridOptions.api.setDatasource(dataSource);
    };

    ConceptViewer.prototype.exportRefsetCSV  = function(){

        var gridOptionsExport = {};

        var cellCallback = function(params) {

            if (params.value.data) {

                var dom = new DOMParser;
                var data = dom.parseFromString('<!doctype html><body>' + params.value.data, 'text/html').body.textContent;

                //if this row has a display value, show that in with the row data in parentheses after
                if (params.value.display === '') {
                    return data;
                } else {

                    var display = dom.parseFromString('<!doctype html><body>' + params.value.display, 'text/html').body.textContent;
                    return display + " (" + data + ")";
                }
            } else {
                return null;
            }
        };

        new agGrid.Grid($("#taxonomy_refsets_results_export").get(0), gridOptionsExport);

        var refsetParams = "?concept_id=" + this.currentConceptID + "&" + jQuery.param({view_params: this.getViewParams()}) + "&taxonomy_refsets_page_number=1&taxonomy_refsets_page_size=10000000;";

        // make an ajax call to get the data
        $.get(gon.routes.taxonomy_get_concept_refsets_path + refsetParams, function( refset_results ) {

            gridOptionsExport.api.setColumnDefs(refset_results.columns);
            gridOptionsExport.api.setRowData(refset_results.data);
            gridOptionsExport.api.exportDataAsCsv({allColumns: true, processCellCallback: cellCallback});
            gridOptionsExport.api.destroy();
        });
    };

    ConceptViewer.prototype.swapLinkIcon = function(linked){

        var linkIcon = $('#komet_concept_panel_tree_link_' + this.viewerID);

        linkIcon.toggleClass("fa-chain", linked);
        linkIcon.toggleClass("fa-chain-broken", !linked);

        if (linked){
            linkIcon.parent().attr("title", this.LINKED_TEXT);
        } else {
            linkIcon.parent().attr("title", this.UNLINKED_TEXT);
        }

        this.toggleTreeIcon();
    };

    ConceptViewer.prototype.toggleTreeIcon = function(){
        $('#komet_concept_panel_tree_show_' + this.viewerID).toggle();
    };

    // This function is passed in to the Parent autosuggest tag as a string and is run when the parent field changes, after all other code executes
    ConceptViewer.prototype.conceptEditorParentOnChange = function(){

        var taxonomyType = $("#komet_create_concept_parent_type_" + this.viewerID).val();
        var fsnNoteSection = $("#komet_create_concept_fsn_note_" + this.viewerID);
        var descriptionTypeSection = $("#komet_create_concept_description_type_section_" + this.viewerID);
        var displaySection = $("#komet_create_concept_description_display_" + this.viewerID);
        var parentField = $("#komet_create_concept_parent_display_" + this.viewerID);
        var preferred_name =  $("#komet_create_concept_description_" + this.viewerID).val();
        var semanticTag = "";

        // depending on the taxonomy type of the parent concept, show or hide certain portions of the form
        if (taxonomyType == UIHelper.SNOMED){

            fsnNoteSection.addClass("hide");
            descriptionTypeSection.addClass("hide");
            displaySection.removeClass("hide");

            semanticTag = this.getSemanticTag(parentField);

            // set the FSN display text [Description (Parent Text)]
            $("#komet_create_concept_fsn_" + this.viewerID).html(preferred_name + semanticTag);

        } else if (taxonomyType == UIHelper.VHAT){

            fsnNoteSection.removeClass("hide");
            descriptionTypeSection.removeClass("hide");
            displaySection.addClass("hide");
        } else {

            fsnNoteSection.removeClass("hide");
            descriptionTypeSection.addClass("hide");
            displaySection.addClass("hide");
        }

        this.setCreateSaveButtonState(parentField.val(), preferred_name);

        // set the Preferred Name display text [Description]
        // $("#komet_create_concept_preferred_name_" + this.viewerID).html(preferred_name);
    }.bind(this);

    ConceptViewer.prototype.createConcept = function() {

        var editorSection = $("#komet_concept_editor_section_" + this.viewerID);

        $("#komet_viewer_" + this.viewerID).on( 'unsavedCheck', function(event){

            var changed = UIHelper.hasFormChanged(editorSection, false, false);
            var shouldStay = false

            if (changed){
                shouldStay = !confirm("You have unsaved changes. Are you sure you want to leave this page?");
            }

            return shouldStay;
        });


        UIHelper.processAutoSuggestTags("#komet_concept_associations_panel_" + this.viewerID);

        var parentField = $("#komet_create_concept_parent_display_" + this.viewerID);

        // TODO - clean up the calling of onchange function to autosuggest field. Do not need to pass function name into tag, remove code from UIHelper and HTML. convert this to anonymous function inside timeout.
        parentField.change(function(){
            setTimeout("WindowManager.viewers[" + this.viewerID + "].conceptEditorParentOnChange()", 0);
        }.bind(this));

        // when the description field changes, update the name display fields
        // a similar function exists for the Parent field (conceptEditorParentOnChange) but is passed into the autosuggest tag
        $("#komet_create_concept_description_" + this.viewerID).change(function(event) {

            var taxonomyType = $("#komet_create_concept_parent_type_" + this.viewerID).val();
            var semanticTag = "";

            // if the taxonomy type of the parent concept is SNOMED, calculate the semantic tag to use for the FSN
            if (taxonomyType == UIHelper.SNOMED){
                semanticTag = this.getSemanticTag(parentField);

                // set the FSN display text [Description (Semantic Tag)]
                var fsn = event.currentTarget.value + semanticTag;
                $("#komet_create_concept_fsn_" + this.viewerID).html(fsn);
            }

            this.setCreateSaveButtonState(parentField.val(), event.currentTarget.value);

            // set the Preferred Name display text [Description]
            // $("#komet_create_concept_preferred_name_" + this.viewerID).html(event.currentTarget.value);
        }.bind(this));

        var thisViewer = this;

        $("#komet_concept_editor_form_" + this.viewerID).submit(function () {

            Common.cursor_wait();

            UIHelper.removePageMessages("#komet_concept_editor_form_" + this.viewerID);

            $.ajax({
                type: "POST",
                url: $(this).attr("action"),
                data: $(this).serialize(), //new FormData($(this)[0]),
                error: function (){Common.cursor_auto();},
                success: function (data) {

                    console.log(data);

                    if (data.concept_id == null){

                        $("#komet_concept_editor_section_" + thisViewer.viewerID).prepend(UIHelper.generatePageMessage("An error has occurred. The concept was not created."));
                        Common.cursor_auto();
                    } else {

                        $("#komet_viewer_" + viewerID).off('unsavedCheck');
                        TaxonomyModule.setViewParams(thisViewer.getViewParams());
                        $.publish(KometChannels.Taxonomy.taxonomyConceptEditorChannel, [ConceptsModule.EDIT, data.concept_id, thisViewer.viewerID, WindowManager.INLINE]);
                    }
                }
            });

            // have to return false to stop the form from posting twice.
            return false;
        });

        if (parentField.val() != ""){
            parentField.change();
        }

        return true;
    };

    ConceptViewer.prototype.getSemanticTag = function(parentElementOrSelector){

        var element;

        // If the type of the first parameter is a string, then use it as a jquery selector, otherwise use as is
        if (typeof parentElementOrSelector === "string"){
            element = $(parentElementOrSelector).val();
        } else {
            element = parentElementOrSelector.val();
        }

        // get the semantic tag from the parent text - the value in parentheses
        var semanticTag = element.match(/\(([^)]+)\)/);

        // if there was a match use that as the semantic tag, otherwise use the parent text
        if (semanticTag){
            semanticTag = " " + semanticTag[0];
        } else {
            semanticTag = " (" + element + ")";
        }

        return semanticTag;
    };

    ConceptViewer.prototype.setCreateSaveButtonState = function(parentValue, descriptionValue){

        var saveButton = $("#komet_concept_save_" + this.viewerID);

        // If the type of the first parameter is a string, then use it as a jquery selector, otherwise use as is
        if (parentValue == "" || descriptionValue == ""){
            UIHelper.toggleFieldAvailability(saveButton, false);
        } else {
            UIHelper.toggleFieldAvailability(saveButton, true);
        }
    };

    ConceptViewer.prototype.validateCreateForm = function () {

        var parent = $("#komet_create_concept_parent_display_" + this.viewerID);
        var description = $("#komet_create_concept_description_" + this.viewerID);
        var hasErrors = false;

        if (parent.val() == undefined || parent.val() == ""){

            $("#komet_create_concept_parent_fields_" + this.viewerID).after(UIHelper.generatePageMessage("The Parent field must be filled in."));
            hasErrors = true;
        }

        if (description.val() == undefined || description.val() == ""){

            description.after(UIHelper.generatePageMessage("The Description field must be filled in."));
            hasErrors = true;
        }

        return hasErrors;
    };

    ConceptViewer.prototype.editConcept = function(attributes, conceptProperties, descriptions, associations, selectOptions){

        var editorSection = $("#komet_concept_editor_section_" + this.viewerID);

        $("#komet_viewer_" + this.viewerID).on( 'unsavedCheck', function(event){

            var changed = UIHelper.hasFormChanged(editorSection, false, false);
            var shouldStay = false

            if (changed){
                shouldStay = !confirm("You have unsaved changes. Are you sure you want to leave this page?");
            }

            return shouldStay;
        });

        var form = $("#komet_concept_editor_form_" + this.viewerID);

        this.loadSelectFieldOptions(selectOptions);

        var attributesPanel = $("#komet_concept_attributes_panel_" + this.viewerID);
        var conceptPropertiesSectionString = "";
        var conceptPropertiesCount;

        for (conceptPropertiesCount = 0; conceptPropertiesCount < conceptProperties.rows.length; conceptPropertiesCount++){

            if (conceptProperties.rows[conceptPropertiesCount].refset){
                break;
            }

            conceptPropertiesSectionString += this.createConceptPropertyRowString(conceptProperties.rows[conceptPropertiesCount], conceptProperties.field_info);
        }

        // create a dom fragment from our included fields structure
        var conceptPropertiesSection = document.createRange().createContextualFragment(conceptPropertiesSectionString);
        attributesPanel.find(".komet-concept-properties-section").append(conceptPropertiesSection);

        var conceptRefsetsSectionString = "";

        for (conceptPropertiesCount; conceptPropertiesCount < conceptProperties.rows.length; conceptPropertiesCount++){

            conceptRefsetsSectionString += this.createConceptPropertyRowString(conceptProperties.rows[conceptPropertiesCount], conceptProperties.field_info);
        }

        // create a dom fragment from our included fields structure
        var conceptRefsetsSection = document.createRange().createContextualFragment(conceptRefsetsSectionString);
        attributesPanel.find(".komet-concept-refsets-section").append(conceptRefsetsSection);

        var descriptionSectionsString = "";
        var descriptionIDs = [];

        for (var i = 0; i < descriptions.length; i++){

            descriptionIDs.push(descriptions[i].description_id);
            descriptionSectionsString += this.createDescriptionRowString(descriptions[i]);
        }

        // create a dom fragment from our included fields structure
        var descriptionSections = document.createRange().createContextualFragment(descriptionSectionsString);
        form.find(".komet-concept-description-title").after(descriptionSections);

        var associationSectionString = "";

        for (var i = 0; i < associations.length; i++){
            associationSectionString += this.createAssociationRowString(associations[i]);
        }

        // create a dom fragment from our included fields structure
        var associationSection = document.createRange().createContextualFragment(associationSectionString);
        $("#komet_concept_associations_panel_" + this.viewerID).find(".komet-concept-section-panel-details").append(associationSection);

        UIHelper.processAutoSuggestTags("#komet_concept_editor_form_" + this.viewerID);

        for (var i = 0; i < descriptionIDs.length; i++){
            this.setAddDialectLinkState(descriptionIDs[i]);
        }

        var thisViewer = this;

        form.submit(function () {

            Common.cursor_wait();
            UIHelper.removePageMessages(form);

            $.ajax({
                type: "POST",
                url: $(this).attr("action"),
                data: $(this).serialize(),
                error: function (){Common.cursor_auto();},
                success: function (data) {

                    if (data.failed.length > 0){

                        var editorSection = $("#komet_concept_editor_section_" + thisViewer.viewerID);

                        var errorString = "Errors occurred, all changes not listed were processed. The following updates were not successful: ";

                        for (var i = 0; i < data.failed.length; i++){

                            errorString += '<div>' + data.failed[i].type + ': ' + data.failed[i].text + '</div>';

                            if (data.failed[i].type == "concept") {

                                editorSection.find("div[id^='komet_concept_edit_concept_row_']").before(UIHelper.generatePageMessage("The status of the concept was not changed."));

                            } else if (data.failed[i].type == "concept property") {

                                editorSection.find("div[id^='komet_concept_edit_concept_properties_row_" + data.failed[i].id + "']").before(UIHelper.generatePageMessage("This property was not processed."));

                            } else if (data.failed[i].type == "description"){

                                var descriptionPanel = editorSection.find("div[id^='komet_concept_description_panel_" + data.failed[i].id + "']");
                                descriptionPanel.before(UIHelper.generatePageMessage("This description was not processed, and none of its properties or dialects were attempted to be processed."));
                                descriptionPanel.css("margin-top", "0px");

                            } else if (data.failed[i].type == "description property"){

                                editorSection.find("div[id^='komet_concept_edit_description_properties_row_" + data.failed[i].id + "']").before(UIHelper.generatePageMessage("This description property was not processed."));

                            } else if (data.failed[i].type == "dialect"){

                                editorSection.find("div[id^='komet_concept_edit_description_dialect_row_" + data.failed[i].id + "']").before(UIHelper.generatePageMessage("This dialect was not processed."));

                            } else if (data.failed[i].type == "association"){

                                editorSection.find("div[id^='komet_concept_association_row_" + data.failed[i].id + "']").before(UIHelper.generatePageMessage("This association was not processed."));
                            }
                        }

                        editorSection.prepend(UIHelper.generatePageMessage(errorString));
                        UIHelper.clearAutoSuggestRecentCache();
                        Common.cursor_auto();
                    } else {

                        $("#komet_viewer_" + viewerID).off('unsavedCheck');
                        TaxonomyModule.setViewParams(thisViewer.getViewParams());
                        $.publish(KometChannels.Taxonomy.taxonomyTreeNodeSelectedChannel, [null, data.concept_id, thisViewer.getViewParams(), thisViewer.viewerID, WindowManager.INLINE]);
                    }
                }
            });

            // have to return false to stop the form from posting twice.
            return false;
        });
    };

    ConceptViewer.prototype.createConceptPropertyRowString = function (rowData, fieldInfo) {

        var rowID = 'komet_concept_edit_concept_properties_row_' + rowData.sememe_instance_id + '_' + this.viewerID;

        var rowString = '<div id="' + rowID + '" class="komet-concept-edit-row komet-concept-edit-concept-properties-row komet-changeable"><div>'
            + '<input type="hidden" name="[properties][' + rowData.sememe_instance_id + '][sememe]" value="' + rowData.sememe_definition_id + '"> '
            + '<span class="form-field komet-concept-edit-concept-properties-sememe"><b>' + rowData.sememe_name + '</b></span></div>'
            + '<div class="komet-containing-block">';

        $.each(rowData.columns, function (fieldID, field) {

            var viewerFieldID = rowData.sememe_instance_id + '_' + fieldID + '_' + this.viewerID;
            var fieldInfoKey = rowData.sememe_definition_id + '_' + fieldID;
            var fieldLabel = fieldInfo[fieldInfoKey].name;

            var data = "";

            if (field.data){
                data = field.data;
            }

            rowString += '<input type="hidden" name="[properties][' + rowData.sememe_instance_id + '][' + fieldID + '][column_number]" value="' + fieldInfo[fieldInfoKey].column_number + '">'
                + '<input type="hidden" name="[properties][' + rowData.sememe_instance_id + '][' + fieldID + '][data_type_class]" value="' + fieldInfo[fieldInfoKey].data_type_class + '">'
                + '<div class="input-group"><label for="komet_concept_edit_concept_properties_' + viewerFieldID + '" class="input-group-addon">' + fieldLabel + '</label>'
                + '<input type="text" id="komet_concept_edit_concept_properties_' + viewerFieldID + '" name="[properties][' + rowData.sememe_instance_id + '][' + fieldID + '][value]" value="' + data + '" class="form-control komet_concept_edit_concept_properties_field">'
                + '</div>';

        }.bind(this));

        rowString +=  '<div>' + this.createSelectField(rowData.sememe_instance_id + "_state_" + this.viewerID, "properties[" + rowData.sememe_instance_id + "][state]", this.selectFieldOptions.state, rowData.state, "Property state") + '</div></div>';

        if (rowData.new) {
            rowString += '<div class="komet-concept-edit-row-tools"><button type="button" class="komet-link-button"'
            + ' onclick="WindowManager.viewers[' + this.viewerID + '].removeItemRow(\'' + rowData.sememe_instance_id + '\', \'' + rowID + '\', \'concept property\', ' + rowData.new + ', this)"'
            + ' title="Remove row"><div class="glyphicon glyphicon-remove"></div></button></div>';
        }

        rowString += '<!-- end komet-concept-edit-concept-properties-row --></div>';

        return rowString;
    };

    ConceptViewer.prototype.createDescriptionRowString = function (rowData) {

        var rowString = "";
        var descriptionID = "";
        var type = "";
        var text = "";
        var state = "";
        var language = "";
        var caseSignificance = "";
        var propertiesSectionClass = " hide";
        var isNew = false;

        if (rowData != null){

            descriptionID = rowData.description_id;
            type = rowData.description_type_id;
            text = rowData.text;
            state = rowData.attributes[0].state;
            language = rowData.language_id;
            caseSignificance = rowData.case_significance_id;
        } else {

            isNew = true;
            descriptionID = window.performance.now().toString().replace(".", "");
        }

        if ($("#komet_concept_editor_properties_" + this.viewerID).is(":checked")){
            propertiesSectionClass = "";
        }

        var rowID = "komet_concept_description_panel_" + descriptionID + "_" + this.viewerID;
        var namePrefix = "descriptions[" + descriptionID + "]";

        rowString += '<div id="' + rowID + '" class="komet-concept-section-panel komet-concept-description-panel">'
            + '<div class="komet-concept-section-panel-details">'
            + '<div class="komet-concept-edit-row komet-concept-edit-description-row komet-changeable">'
            + '<div>' + this.createSelectField(descriptionID + "_description_type_" + this.viewerID, namePrefix + "[description_type]", this.selectFieldOptions.descriptionType, type, "Description Type") + '</div>'
            + '<div><input type="text" id="komet_concept_edit_description_type_' + descriptionID + '_' + this.viewerID + '" name="' + namePrefix + '[text]" value="' + text + '" class="form-control komet_concept_edit_description_type" aria-label="Description Type"></div>'
            + '<div>' + this.createSelectField(descriptionID + "_description_language_" + this.viewerID, namePrefix + "[description_language]", this.selectFieldOptions.language, language, "Description Language") + '</div>'
            + '<div>' + this.createSelectField(descriptionID + "_description_case_significance_" + this.viewerID, namePrefix + "[description_case_significance]", this.selectFieldOptions.caseSignificance, caseSignificance, "Description Case Significance") + '</div>'
            + '<div>' + this.createSelectField(descriptionID + "_description_state_" + this.viewerID, namePrefix + "[description_state]", this.selectFieldOptions.state, state, "Description State") + '</div>';

        if (isNew){
            rowString += '<div class="komet-concept-edit-row-tools">'
                + '<button type="button" class="komet-link-button" onclick="WindowManager.viewers[' + this.viewerID + '].removeItemRow(\'' + descriptionID + '\', \'' + rowID + '\', \'description\', ' + isNew + ', this)" title="Remove row" aria-label="Remove row">'
                + '<div class="glyphicon glyphicon-remove"></div></button></div>';
        }

        rowString += '</div>'
            + '<div class="komet-indent-block komet-concept-description-dialect-section">'
            + '<div class="komet-concept-section-title komet-concept-description-title">Dialects'
            + '<div class="komet-flex-right">'
            + '<button type="button" class="komet-link-button komet-concept-add-description-dialect" onclick="WindowManager.viewers[' + this.viewerID + '].addDialectRow(\'' + descriptionID + '\')">Add Dialect'
            + '<div class="glyphicon glyphicon-plus-sign"></div></button></div>';

        rowString += '</div>';

        if (rowData && rowData.attributes) {

            $.each(rowData.attributes, function (index, attribute) {

                if (attribute.label == "Dialect"){
                    rowString += this.createDescriptionDialectRowString(descriptionID, attribute);
                }
            }.bind(this));
        }

        rowString += '</div>'
            + '<div class="komet-indent-block komet-concept-description-properties-section' + propertiesSectionClass + '"><div class="komet-concept-section-title komet-concept-description-title">Properties'
            + '<div class="komet-flex-right"><button type="button" class="komet-link-button komet-concept-add-description-property" onclick="WindowManager.viewers[' + this.viewerID + '].addPropertyRow(\'' + descriptionID + '\', this, \'description\')">Add Property <div class="glyphicon glyphicon-plus-sign"></div></button></div></div>';

        var propertyCount;

        if (rowData && rowData.nested_properties) {

            for (propertyCount = 0; propertyCount < rowData.nested_properties.data.length; propertyCount++){

                if (rowData.nested_properties.data[propertyCount].refset){
                    break;
                }

                rowString += this.createDescriptionPropertyRowString(descriptionID, rowData.nested_properties.data[propertyCount], rowData.nested_properties.field_info);
            }
        }

        rowString += '</div>'
            + '<div class="komet-indent-block komet-concept-description-refsets-section' + propertiesSectionClass + '"><div class="komet-concept-section-title komet-concept-description-title">Refsets'
            + '<div class="komet-flex-right"><button type="button" class="komet-link-button komet-concept-add-description-refset" onclick="WindowManager.viewers[' + this.viewerID + '].addPropertyRow(\'' + descriptionID + '\', this, \'description refset\')">Add Refset <div class="glyphicon glyphicon-plus-sign"></div></button></div></div>';

        if (rowData && rowData.nested_properties) {

            for (propertyCount; propertyCount < rowData.nested_properties.data.length; propertyCount++){
                rowString += this.createDescriptionPropertyRowString(descriptionID, rowData.nested_properties.data[propertyCount], rowData.nested_properties.field_info);
            }
        }

        rowString += '<!-- end komet-indent-block --></div><!-- end komet-concept-section-panel-details --></div><!-- end komet_concept_description_panel --></div>';

        return rowString;
    }.bind(this);

    ConceptViewer.prototype.createDescriptionPropertyRowString = function (descriptionID, rowData, fieldInfo) {

        var propertyID = descriptionID + '_' + rowData.sememe_instance_id;
        var rowID = 'komet_concept_edit_description_properties_row_' + propertyID + '_' + this.viewerID;
        var namePrefix = "descriptions[" + descriptionID + "][properties][" + rowData.sememe_instance_id + "]";

        var rowString = '<div id="' + rowID + '" class="komet-concept-edit-row komet-concept-edit-description-properties-row komet-changeable"><div>'
            + '<input type="hidden" name="' + namePrefix + '[sememe]" value="' + rowData.sememe_definition_id + '"> '
            + '<input type="hidden" name="' + namePrefix + '[sememe_name]" value="' + rowData.sememe_name + '"> '
            + '<span class="form-field komet-concept-edit-description-properties-sememe"><b>' + rowData.sememe_name + '</b></span></div>'
            + '<div class="komet-containing-block">';

        $.each(rowData.columns, function (fieldID, field) {

            var viewerFieldID = propertyID + '_' + fieldID + '_' + this.viewerID;
            var fieldInfoKey = rowData.sememe_definition_id + '_' + fieldID;
            var fieldLabel = fieldInfo[fieldInfoKey].name;

            var data = "";

            if (field.data){
                data = field.data;
            }

            rowString += '<input type="hidden" name="' + namePrefix + '[' + fieldID + '][column_number]" value="' + fieldInfo[fieldInfoKey].column_number + '">'
                + '<input type="hidden" name="' + namePrefix + '[' + fieldID + '][data_type_class]" value="' + fieldInfo[fieldInfoKey].data_type_class + '">'
                + '<div class="input-group"><label for="komet_concept_edit_description_properties_' + viewerFieldID + '" class="input-group-addon">' + fieldLabel + '</label>';

            if (fieldInfo[fieldInfoKey].column_display == 'text'){

                rowString += '<input type="text" id="komet_concept_edit_description_properties_' + viewerFieldID + '" name="' + namePrefix + '[' + fieldID + '][value]" value="' + data + '" class="form-control komet_concept_edit_description_properties_field">'
                    + '</div>';
            } else {

                var dropdownOptions = this.createSelectFieldOptions(fieldInfo[fieldInfoKey].dropdown_options);
                rowString += this.createSelectField("description_properties_" + viewerFieldID, namePrefix + "[" + fieldID + "][value]", dropdownOptions, data, fieldLabel, "komet_concept_edit_description_properties_field")
                    + '</div>';
            }

        }.bind(this));

        rowString += '<div>' + this.createSelectField(propertyID + '_state_' + this.viewerID, namePrefix + "[state]", this.selectFieldOptions.state, rowData.state, "state") + '</div>'
            + '</div>';

        if (rowData.new){
            rowString += '<div class="komet-concept-edit-row-tools">'
                + '<button type="button" class="komet-link-button" onclick="WindowManager.viewers[' + this.viewerID + '].removeItemRow(\'' + rowData.sememe_instance_id + '\', \'' + rowID + '\', \'description property\', ' + rowData.new + ', this)" title="Remove row" aria-label="Remove row">'
                + '<div class="glyphicon glyphicon-remove"></div></button></div>';
        }

        rowString += '<!-- end komet-concept-edit-description-properties-row --></div>';

        return rowString;
    };

    ConceptViewer.prototype.createDescriptionDialectRowString = function (descriptionID, rowData) {

        // TODO - see if we want to ever handle dialects like attached sememes, where they can be updated as well. If not remove the remenants of that code.
        var dialectID = "";
        var dialect = "";
        var acceptability = "";
        var state = "";
        var isNew = false;
        var rowString = null;
        var namePrefix = "";
        var idPrefix = "";

        if (rowData != null){

            dialectID = rowData.dialect_instance_id;
            dialect = rowData.dialect_definition_id
            acceptability = rowData.acceptability_id;
            state = rowData.state;
            namePrefix = "descriptions[" + descriptionID + "][dialects][" + dialectID + "]";
            idPrefix = descriptionID + "_" + dialectID;

            rowString = '<div class="komet-concept-edit-row komet-concept-edit-description-dialect-row">'
                + '<input type="hidden" name="' + namePrefix + '[dialect]" value="' + dialect + '">'
                + '<input type="hidden" name="' + namePrefix + '[acceptability]" value="' + acceptability + '">'
                + '<div>' + rowData.text + '</div>'
                + '<div>' + rowData.acceptability_text + '</div>';
        } else {

            isNew = true;
            dialectID = window.performance.now().toString().replace(".", "");
            var viewerDialectID = dialectID + '_' + this.viewerID;
            var rowID = 'komet_concept_edit_description_dialect_row_' + viewerDialectID;
            idPrefix = descriptionID + "_" + dialectID;
            namePrefix = "descriptions[" + descriptionID + "][dialects][" + dialectID + "]";

            rowString = '<div id="' + rowID + '" class="komet-concept-edit-row komet-concept-edit-description-dialect-row">'
                + '<div>' + this.createSelectField(idPrefix + "_dialect_" + this.viewerID, namePrefix + "[dialect]", this.selectFieldOptions.dialect, dialect, "dialect", "Dialect State") + '</div>'
                + '<div>' + this.createSelectField(idPrefix + "_acceptability_" + this.viewerID, namePrefix + "[acceptability]", this.selectFieldOptions.acceptability, acceptability, "acceptability", "Dialect Acceptability") + '</div>';
        }

        rowString += '<div>' + this.createSelectField(idPrefix + "_state_" + this.viewerID, namePrefix + "[state]", this.selectFieldOptions.state, state, "Dialect State") + '</div>'

        if (isNew){
            rowString += '<div class="komet-concept-edit-row-tools">'
                + '<button type="button" class="komet-link-button" onclick="WindowManager.viewers[' + this.viewerID + '].removeItemRow(\'' + dialectID + '\', \'' + rowID + '\', \'dialect\', ' + isNew + ', this)" title="Remove row" aria-label="Remove row">'
                + '<div class="glyphicon glyphicon-remove"></div>'
                + '</button></div>';
        }

        rowString += '</div>';

        return rowString;
    };

    ConceptViewer.prototype.createAssociationRowString = function (rowData) {

        var rowString = "";
        var associationID = "";
        var typeID = "";
        var state = "";
        var targetID = "";
        var targetText = "";
        var targetTaxonomyType = "";
        var isNew = false;
        var typeDisplay = "";

        if (rowData != null){

            associationID = rowData.id;
            typeDisplay = '<span class="komet-concept-edit-association-type"><input type="hidden" name="associations[' + associationID + '][association_type]" value="' + rowData.type_id + '">'
                + '<b>' + rowData.type_text + '</b></span>';
            state = rowData.state;

            if (rowData.target_id){

                targetID = rowData.target_id;
                targetText = rowData.target_text;
                targetTaxonomyType = rowData.target_taxonomy_type;
            }

        } else {

            isNew = true;
            associationID = window.performance.now().toString().replace(".", "");
            typeDisplay = this.createSelectField(associationID + "_association_type_" + this.viewerID, "associations[" + associationID + "][association_type]", this.selectFieldOptions.associationType, "", "Association type");

        }

        var rowID = "komet_concept_association_row_" + associationID + "_" + this.viewerID;

        rowString += '<div id="' + rowID + '" class="komet-concept-edit-row komet-concept-edit-association-row komet-changeable">'
            + '<div>' + typeDisplay + '</div>'
            + '<div><autosuggest id-base="komet_concept_edit_association_value_' + associationID + '" '
            + 'id-postfix="_' + this.viewerID + '" '
            + 'name="associations[' + associationID + '][target" '
            + 'name-format="array" '
            + 'value="' + targetID + '" '
            + 'display-value="' + targetText + '" '
            + 'type-value="' + targetTaxonomyType + '" '
            + 'classes="komet-concept-edit-association-value">'
            + '</autosuggest></div>'
            + '<div>' + this.createSelectField(associationID + "_association_state_" + this.viewerID, "associations[" + associationID + "][association_state]", this.selectFieldOptions.state, state, "Association State") + '</div>';

        if (isNew){
            rowString += '<div class="komet-concept-edit-row-tools">'
                + '<button type="button" class="komet-link-button" onclick="WindowManager.viewers[' + this.viewerID + '].removeItemRow(\'' + associationID + '\', \'' + rowID + '\', \'association\', ' + isNew + ', this)" title="Remove row" aria-label="Remove row">'
                + '<div class="glyphicon glyphicon-remove"></div>'
                + '</button></div>';
        }

        rowString += '</div>';

        return rowString;
    }.bind(this);

    ConceptViewer.prototype.addDescriptionRow = function () {

        var editorSection = $("#komet_concept_editor_section_" + this.viewerID);
        var appendAfter = editorSection.find(".komet-concept-description-panel");

        if (appendAfter.length > 0){
            appendAfter = appendAfter.last();
        } else {
            appendAfter = editorSection.find(".komet-concept-description-title");
        }

        // generate the new row string and create a dom fragment it
        var descriptionRowString = this.createDescriptionRowString(null);
        var propertyRow = document.createRange().createContextualFragment(descriptionRowString);

        appendAfter.after(propertyRow);
        UIHelper.processAutoSuggestTags(editorSection);

        editorSection.change();
    };

    ConceptViewer.prototype.addPropertyRow = function (descriptionID, addElement, property_type) {

        var formID = "komet_concept_add_property_form_" + this.viewerID;

        var addRowString = '<form action="' + gon.routes.taxonomy_get_new_property_info_path + '" id="' + formID + '" class="komet-concept-add-property-form">'
            + '<autosuggest id-base="komet_concept_add_property_sememe" '
            + 'id-postfix="_' + this.viewerID + '" '
            + 'name="sememe" '
            + 'label="Search for a concept to use as a ' + property_type + ' property" '
            + 'restrict-search="' + UIHelper.RECENTS_SEMEME + '"'
            + 'classes="komet-concept-add-property-sememe">'
            + '</autosuggest></form>';

        var confirmCallback = function(buttonClicked){

            if (buttonClicked != 'cancel') {

                var thisViewer = this;
                var form = $("#" + formID);

                form.submit(function () {

                    $.ajax({
                        type: "POST",
                        url: $(this).attr("action"),
                        data: $(this).serialize(),
                        success: function (sememe_info) {

                            var editorSection = $("#komet_concept_editor_section_" + thisViewer.viewerID);

                            if (sememe_info.data == null){
                                editorSection.prepend(UIHelper.generatePageMessage("An error has occurred. The property was not created."));
                            } else {

                                sememe_info.data.new = true;

                                var section = "";
                                var rowString = "";

                                if (property_type == "description"){

                                    section = $("#komet_concept_description_panel_" + descriptionID + "_" + thisViewer.viewerID).find(".komet-concept-description-properties-section");
                                    rowString = thisViewer.createDescriptionPropertyRowString(descriptionID, sememe_info.data, sememe_info.field_info);

                                } else if (property_type == "description refset") {

                                    section = $("#komet_concept_description_panel_" + descriptionID + "_" + thisViewer.viewerID).find(".komet-concept-description-refsets-section");
                                    rowString = thisViewer.createDescriptionPropertyRowString(descriptionID, sememe_info.data, sememe_info.field_info);

                                } else if (property_type == "concept") {

                                    section = $("#komet_concept_attributes_panel_" + thisViewer.viewerID).find(".komet-concept-properties-section");
                                    rowString = thisViewer.createConceptPropertyRowString(sememe_info.data, sememe_info.field_info);
                                } else {

                                    section = $("#komet_concept_attributes_panel_" + thisViewer.viewerID).find(".komet-concept-refsets-section");
                                    rowString = thisViewer.createConceptPropertyRowString(sememe_info.data, sememe_info.field_info);
                                }


                                // generate the new row string and create a dom fragment it
                                var row = document.createRange().createContextualFragment(rowString);

                                section.append(row);
                                UIHelper.processAutoSuggestTags(section);

                                editorSection.change();
                            }
                        }
                    });

                    // have to return false to stop the form from posting twice.
                    return false;
                });

                form.submit();
            }

        }.bind(this);

        UIHelper.generateConfirmationDialog("Add a Property", addRowString, confirmCallback, "Add", addElement);
        UIHelper.processAutoSuggestTags("#" + formID);
    };

    ConceptViewer.prototype.addDialectRow = function (descriptionID) {

        var section = $("#komet_concept_description_panel_" + descriptionID + "_" + this.viewerID).find(".komet-concept-description-dialect-section");

        // generate the new row string and create a dom fragment it
        var rowString = this.createDescriptionDialectRowString(descriptionID);
        var row = document.createRange().createContextualFragment(rowString);

        section.append(row);
        UIHelper.processAutoSuggestTags(section);
        this.setAddDialectLinkState(descriptionID);

        $("#komet_concept_editor_section_" + this.viewerID).change();
    };

    ConceptViewer.prototype.addAssociationRow = function () {

        var section = $("#komet_concept_associations_panel_" + this.viewerID).find(".komet-concept-section-panel-details");

        // generate the new row string and create a dom fragment it
        var rowString = this.createAssociationRowString(null);
        var row = document.createRange().createContextualFragment(rowString);

        section.append(row);
        UIHelper.processAutoSuggestTags(section);

        $("#komet_concept_editor_section_" + this.viewerID).change();
    };

    ConceptViewer.prototype.setAddDialectLinkState = function (descriptionID) {

        var descriptionPanel = $("#komet_concept_description_panel_" + descriptionID + "_" + this.viewerID);
        var addDialect = descriptionPanel.find(".komet-concept-add-description-dialect");

        // find all dialect rows under the description that have not been removed
        if (descriptionPanel.find(".komet-concept-edit-description-dialect-row").not(".komet-removed").length < this.selectFieldOptions.dialect.length){
            addDialect.removeClass("komet-disabled");
        } else {
            addDialect.addClass("komet-disabled");
        }
    };

    ConceptViewer.prototype.removeItemRow = function (conceptID, rowID, type, isNew, closeElement) {

        var confirmCallback = function(buttonClicked){

            if (buttonClicked != 'cancel') {

                var descriptionID = null;
                var row = $("#" + rowID);

                // if this is a dialect then get the related description ID.
                if (type == "dialect"){

                    var descriptionSection = row.closest(".komet-concept-description-panel");

                    // get the description ID from the section ID - the in between the '_'s after 'description_panel'
                    descriptionID = descriptionSection.attr('id').match(/description_panel_([^)]+)_/)[1];
                }

                if (isNew){
                    row.remove();
                } else {

                    row.addClass("hide komet-removed");
                    row.html('<input type="hidden" name="remove[' + conceptID + ']" value="">');
                    //row.html('<input type="hidden" name="remove[' + type + '][' + conceptID + ']" value="' + conceptID + '">');
                }

                // if this is a dialect then check the Add Dialect link state.
                if (type == "dialect"){
                    this.setAddDialectLinkState(descriptionID);
                }
            }

        }.bind(this);

        UIHelper.generateConfirmationDialog("Delete " + type + "?", "Are you sure you want to remove this " + type + "?", confirmCallback, "Yes", closeElement);
    };

    ConceptViewer.prototype.createSelectField = function (idPrefix, namePrefix, options, selectedItem, label, classes) {

        var id = "komet_concept_edit_" + idPrefix;

        if (classes == undefined || classes == null){
            classes = "";
        }

        var fieldString = '<select id="' + id + '"'
            + ' name="' + namePrefix + '"'
            + ' class="form-control ' + classes + '"'
            + ((label) ? (' aria-label="' + label) + '"' : '')
            + '>';

        for (var i = 0; i < options.length; i++) {

            fieldString += '<option ';

            if (selectedItem != null && selectedItem.toString().toLowerCase() == options[i].value.toString().toLowerCase()) {
                fieldString += 'selected="selected" ';
            }

            fieldString += 'value="' + options[i].value + '">' + options[i].label + '</option>';
        }

        fieldString += '</select>';

        return fieldString;
    }.bind(this);

    ConceptViewer.prototype.loadSelectFieldOptions = function (selectOptions) {

        this.selectFieldOptions = {};

        this.selectFieldOptions.descriptionType = this.createSelectFieldOptions(selectOptions.descriptionType);

        this.selectFieldOptions.language = this.createSelectFieldOptions(selectOptions.language);

        this.selectFieldOptions.dialect = this.createSelectFieldOptions(selectOptions.dialect);

        this.selectFieldOptions.caseSignificance = this.createSelectFieldOptions(selectOptions.case);

        this.selectFieldOptions.acceptability = this.createSelectFieldOptions(selectOptions.acceptability);

        this.selectFieldOptions.associationType = this.createSelectFieldOptions(selectOptions.associationType);

        this.selectFieldOptions.state = [
            {value: "Active", label: "Active"},
            {value: "Inactive", label: "Inactive"}
        ];
    };

    ConceptViewer.prototype.createSelectFieldOptions = function (options) {

        var optionArray = [];

        for (var i = 0; i < options.length; i++){
            optionArray.push({value: options[i].concept_id, label: options[i].text});
        }

        return optionArray;
    }

    ConceptViewer.prototype.validateEditForm = function () {

        //var parent = $("#komet_create_concept_parent_display_" + this.viewerID);
        //var description = $("#komet_create_concept_description_" + this.viewerID);
        var hasErrors = false;

        //if (parent.val() == undefined || parent.val() == ""){
        //
        //    $("#komet_create_concept_parent_fields_" + this.viewerID).after(UIHelper.generatePageMessage("The Parent field must be filled in."));
        //    hasErrors = true;
        //}
        //
        //if (description.val() == undefined || description.val() == ""){
        //
        //    description.after(UIHelper.generatePageMessage("The Description field must be filled in."));
        //    hasErrors = true;
        //}

        return hasErrors;
    };

    ConceptViewer.prototype.toggleProperties = function(){
        $("#komet_viewer_" + this.viewerID).find(".komet-concept-description-properties-section").toggleClass("hide");
    };

    ConceptViewer.prototype.showSaveSection = function (sectionName) {

        var saveSection = $("#komet_concept_save_section_" + this.viewerID);
        var confirmSection = $("#komet_concept_confirm_section_" + this.viewerID);
        var editorSection = $("#komet_concept_editor_section_" + this.viewerID);

        var form = $("#komet_concept_editor_form_" + this.viewerID);
        UIHelper.removePageMessages(form);

        if (sectionName == 'confirm'){

            var hasErrors = false;

            if (this.viewerAction == ConceptsModule.CREATE){
                hasErrors = this.validateCreateForm();
            } else {
                hasErrors = this.validateEditForm();
            }

            if (hasErrors){

                editorSection.prepend(UIHelper.generatePageMessage("Please fix the errors below."));
                return false;
            }

            var confirmCallback = function(buttonClicked) {

                var showChangesCheckbox = $("#komet_concept_editor_show_changes_" + this.viewerID);

                if (showChangesCheckbox.length == 0 || !showChangesCheckbox[0].checked){
                    UIHelper.toggleChangeHighlights(editorSection, false);
                }

                if (buttonClicked != 'cancel') {
                    form.submit();
                }
            }.bind(this);

            console.log(UIHelper.hasFormChanged(editorSection, true, true));
            UIHelper.generateConfirmationDialog("Save Concept", "Are you sure you want to commit your changes?", confirmCallback, "Save", "#komet_concept_save_" + this.viewerID);
            //saveSection.toggleClass("hide");
            //confirmSection.toggleClass("hide");

        } else {

            //saveSection.toggleClass("hide");
            //confirmSection.toggleClass("hide");
            UIHelper.toggleChangeHighlights(editorSection, false);
        }
    };

    // TODO - Find ways to make this more efficient
    ConceptViewer.prototype.toggleEditorChangeHighlights = function(checkbox){

        var editorSection = $("#komet_concept_editor_section_" + this.viewerID);

        if (checkbox.checked){

            UIHelper.hasFormChanged(editorSection, true, true);

            editorSection.change(function(){
                UIHelper.hasFormChanged(editorSection, true, true);
            });
        } else {

            editorSection.off("change");
            UIHelper.toggleChangeHighlights(editorSection, false);
        }
    };

    // call our constructor function
    this.init(viewerID, currentConceptID, viewerAction);
};
