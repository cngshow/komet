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

    ConceptViewer.prototype.togglePanelDetails = function(panelID, callback, preserveState) {

        // get the panel's expander icon, or all expander icons if this is the top level expander
        var expander = $("#" + panelID + " .glyphicon-plus-sign, #" + panelID + " .glyphicon-minus-sign");
        var drawer = $("#" + panelID + " .komet-concept-section-panel-details");
        var topLevelExpander = expander.parent().hasClass('komet-concept-body-tools');
        var open;

        // if the user clicked on the top level concept expander, change the associated text label
        if (topLevelExpander) {

            var item_text = expander[0].nextElementSibling;

            if (item_text.innerHTML == "Expand All") {

                item_text.innerHTML = "Collapse All";
                open = true;

            } else {

                item_text.innerHTML = "Expand All";
                open = false;
            }
        } else {
            open = expander.hasClass("glyphicon-plus-sign");
        }

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

        // save state if needed, and if there is a callback run it, passing the panel ID, open state, and concept ID.
        if(topLevelExpander){

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

        var stated = $("#komet_concept_stated_inferred_" + this.viewerID)[0].value

        if (this.trees.hasOwnProperty(this.PARENTS_TREE) && this.trees[this.PARENTS_TREE].tree.jstree(true)){

            this.trees[this.PARENTS_TREE].tree.jstree(true).destroy();
            this.trees[this.CHILDREN_TREE].tree.jstree(true).destroy();
        }

        this.trees[this.PARENTS_TREE] = new KometTaxonomyTree(this.PARENTS_TREE, stated, true, this.currentConceptID, false, this.viewerID);
        this.trees[this.CHILDREN_TREE] = new KometTaxonomyTree(this.CHILDREN_TREE, stated, false, this.currentConceptID, false, this.viewerID, false);

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
            TaxonomyModule.getStatedView(),
            function (foundNodeId) {},
            true
        );
    };

    ConceptViewer.prototype.loadRefsetGrid = function(panelID, open, conceptID) {

        if(!(!this.refsetGridOptions && open)){
            return;
        }

        // If a grid already exists destroy it or it will create a second grid
        if (this.refsetGridOptions) {
            this.refsetGridOptions.api.destroy();
        }

        // set the options for the result grid
        this.refsetGridOptions = {
            enableColResize: true,
            enableSorting: true,
            suppressCellSelection: true,
            rowSelection: "single",
            onGridReady: onGridReady,
            rowModelType: 'pagination'
        };

        function onGridReady(event) {
            event.api.sizeColumnsToFit();
        }

        new agGrid.Grid($("#" + this.REFSET_GRID).get(0), this.refsetGridOptions);
        this.getRefsetResultData(conceptID);
    };

    ConceptViewer.prototype.getRefsetResultData = function(uuid) {

        // load the parameters from the form to add to the query string sent in the ajax data call
        var pageSize = 25;
        var refsetsParams = "?concept_id=" + uuid + "&stated=" + this.getStatedView();

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

                if (['uuid', 'nid', 'sctid'].indexOf(params.colDef.data_type) >= 0) {
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

            pageSize: pageSize,
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

    ConceptViewer.prototype.swapLinkIcon = function(linked){

        var linkIcon = $('#komet_concept_panel_tree_link_' + this.viewerID);

        linkIcon.toggleClass("fa-chain", linked);
        linkIcon.toggleClass("fa-chain-broken", !linked);

        if (linked){
            linkIcon.attr("title", this.LINKED_TEXT);
        } else {
            linkIcon.attr("title", this.UNLINKED_TEXT);
        }

        this.toggleTreeIcon();
    };

    ConceptViewer.prototype.toggleTreeIcon = function(){
        $('#komet_concept_panel_tree_show_' + this.viewerID).toggle();
    };

    ConceptViewer.prototype.getStatedView = function(){
        return $('#komet_concept_stated_inferred_' + this.viewerID)[0].value;
    };

    ConceptViewer.prototype.exportCSV  = function(){
        this.refsetGridOptions.api.exportDataAsCsv({allColumns: true});
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

        $("#komet_create_concept_form_" + this.viewerID).submit(function () {

            $("#komet_create_concept_form_" + this.viewerID).find(".komet-form-error, .komet-form-field-error").remove();

            $.ajax({
                type: "POST",
                url: $(this).attr("action"),
                data: $(this).serialize(), //new FormData($(this)[0]),
                success: function (data) {

                    console.log(data);

                    if (data.concept_id == null){
                        $("#komet_concept_editor_section_" + thisViewer.viewerID).prepend(UIHelper.generateFormErrorMessage("An error has occurred. The concept was not created."));
                    } else {

                        TaxonomyModule.tree.reloadTreeStatedView(TaxonomyModule.getStatedView(), false);
                        $.publish(KometChannels.Taxonomy.taxonomyConceptEditorChannel, [data.concept_id, thisViewer.viewerID, WindowManager.INLINE]);
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

            $("#komet_create_concept_parent_fields_" + this.viewerID).after(UIHelper.generateFormErrorMessage("The Parent field must be filled in."));
            hasErrors = true;
        }

        if (description.val() == undefined || description.val() == ""){

            description.after(UIHelper.generateFormErrorMessage("The Description field must be filled in."));
            hasErrors = true;
        }

        return hasErrors;
    };

    ConceptViewer.prototype.editConcept = function(attributes, descriptions, selectOptions){

        var divtext = "";
        var editSection = $("#komet_concept_editor_section_" + this.viewerID);

        this.loadSelectFieldOptions(selectOptions);

        this.selectItemByValue(document.getElementById('komet_concept_Status'),attributes[1].value);

        if ( attributes[2].value == 'Primitive') {
            divtext = "<div class='komet-tree-node-icon komet-tree-node-primitive' title=''" + attributes[2].value + "'></div>"
        } else {
            divtext = "<div class='komet-tree-node-icon komet-tree-node-defined' title='" + attributes[2].value + "'></div>"
        }

        $("#definedDiv").html(divtext);

        this.selectItemByValue(document.getElementById('komet_concept_defined'),attributes[2].value);

        var descriptionSectionsString = "";
        var firstSection = true;

        for (var i = 0; i < descriptions.length; i++){

            descriptionSectionsString += this.createDescriptionRowString(firstSection, descriptions[i]);
            firstSection = false;
        }

        // create a dom fragment from our included fields structure
        var descriptionSections = document.createRange().createContextualFragment(descriptionSectionsString);
        editSection.find(".komet-concept-description-title").after(descriptionSections);

        UIHelper.processAutoSuggestTags("#komet_concept_edit_form_" + this.viewerID);
    };

    ConceptViewer.prototype.selectItemByValue = function(elmnt, value) {

        for (var i=0; i < elmnt.options.length; i++)
        {
            if (elmnt.options[i].value.toUpperCase() == value)
                elmnt.selectedIndex = i;
        }
    };

    ConceptViewer.prototype.createDescriptionRowString = function (firstSection, rowData) {

        var descriptionRow = "";
        var uuid = "";
        var type = "";
        var text = "";
        var state = "";
        var acceptability = "";
        var language = "";
        var caseSignificance = "";

        if (rowData != null){

            uuid = rowData.uuid;
            type = rowData.description_type_short;
            text = rowData.text;
            state = rowData.attributes[0].state;
            language = rowData.language_id;
            caseSignificance = rowData.case_significance;
        }

        if (!firstSection){
            descriptionRow = '<div class="concept-section-panel-spacer"></div>';
        }

        descriptionRow += '<div id="komet_concept_description_panel_' + this.viewerID + '_' + uuid + '" class="komet-concept-section-panel komet-concept-description-panel">'
            + '<div class="komet-concept-section-panel-details">'
            + '<div class="komet-concept-edit-row komet-concept-edit-description-row">'
            + '<div>' + this.createSelectField("description_type", uuid, this.selectFieldOptions.descriptionType, type) + '</div>'
            + '<div><input type="text" id="komet_concept_edit_description_type_' + uuid + '_' + this.viewerID + '" name="descriptions[' + uuid + '][type]" value="' + text + '" class="form-control komet_concept_edit_description_type"></div>'
            + '<div>' + this.createSelectField("description_acceptability", uuid, this.selectFieldOptions.acceptability, acceptability) + '</div>'
            + '<div>' + this.createSelectField("description_state", uuid, this.selectFieldOptions.state, state) + '</div>'
            + '<div>' + this.createSelectField("description_language", uuid, this.selectFieldOptions.language, language) + '</div>'
            + '<div>' + this.createSelectField("description_case_significance", uuid, this.selectFieldOptions.caseSignificance, caseSignificance) + '</div>'
            + '<div class="komet-concept-edit-row-tools"><div class="glyphicon glyphicon-remove" onclick=""></div></div>'
            + '</div>'
            + '<div class="komet-indent-block"><div class="komet-concept-section-title komet-concept-description-title">Properties'
            + '<div class="komet-flex-right">Add Property <div class="glyphicon glyphicon-plus-sign" onclick=""></div></div></div>';

        if (rowData.nested_properties) {

            $.each(rowData.nested_properties.data, function (index, property) {
                descriptionRow += this.createDescriptionPropertyRowString(uuid, property, rowData.nested_properties.field_info);
            }.bind(this));
        }

        descriptionRow += '<!-- end komet-indent-block --></div><!-- end komet-concept-section-panel-details --></div><!-- end komet_concept_description_panel --></div>';

        return descriptionRow;
    }.bind(this);

    ConceptViewer.prototype.createDescriptionPropertyRowString = function (description_id, property, fieldInfo) {

        var propertyString = '<div class="komet-concept-edit-row komet-concept-edit-description-properties-row"><div>';

        if (property.new){

            propertyString += '<autosuggest id-base="komet_concept_edit_description_properties_sememe_' + description_id + '_' + property.id + '" '
                + 'id-postfix="_' + this.viewerID + '" '
                + 'name="descriptions[' + description_id + '][' + property.id + '][sememe" '
                + 'nameFormat="array" '
                + 'value="' + property.uuid + '" '
                + 'display-value="' + property.sememe_name + '" '
                + 'type-value="" '
                + 'classes="komet-concept-edit-description-properties-sememe">'
                + '</autosuggest>';
        } else {

            propertyString += '<input type="hidden" name="descriptions[' + description_id + '][' + property.id + '][sememe]" value="' + property.uuid + '"> '
                //+ '<input class="ui-state-disabled form-field komet-concept-edit-description-properties-sememe" value="' + property.sememe_name + '"> ';
                + '<span class="form-field komet-concept-edit-description-properties-sememe"><b>' + property.sememe_name + '</b></span>';
        }

        propertyString += '</div>';

        $.each(property.columns, function (fieldID, field) {

            var fieldLabel = fieldInfo[fieldID].name;

            propertyString += '<div class="input-group"><label for="komet_concept_edit_description_properties_' + fieldID + '_' + description_id + '_' + property.id + '_' + this.viewerID + '" class="input-group-addon">' + fieldLabel + '</label>'
                + '<input type="text" id="komet_concept_edit_description_properties_' + fieldID + '_' + description_id + '_' + property.id + '_' + this.viewerID + '" name="descriptions[' + description_id + '][' + property.id + '][' + fieldID + ']" value="' + field.data + '" class="form-control komet_concept_edit_description_properties_field">'
                + '</div>';

        }.bind(this));

        propertyString += '<div class="komet-concept-edit-row-tools"><div class="glyphicon glyphicon-remove" onclick=""></div></div><!-- end komet-concept-edit-description-properties-row --></div>';

        return propertyString;
    };

    ConceptViewer.prototype.createSelectField = function (fieldName, fieldID, options, selectedItem) {

        var fieldString = '<select id="komet_concept_edit_' + fieldName + '_' + fieldID + '_' + this.viewerID + '" name="descriptions[' + fieldID + '][' + fieldName + ']" class="form-control komet_concept_edit_' + fieldName + '">';

        for (var i = 0; i < options.length; i++){

            fieldString += '<option ';

            if (selectedItem === options[i].value) {
                fieldString += 'selected="selected" ';
            }

            fieldString += 'value="' + options[i].value + '">' + options[i].label + '</option>';
        }

        fieldString += '</select>';

        return fieldString;
    }.bind(this);

    ConceptViewer.prototype.loadSelectFieldOptions = function (selectOptions) {

        function createOptions(options){

            var optionArray = [];

            for (var i = 0; i < options.length; i++){
                optionArray.push({value: options[i].concept_id, label: options[i].text});
            }

            return optionArray;
        }

        this.selectFieldOptions = {};

        this.selectFieldOptions.descriptionType = createOptions(selectOptions.descriptionType);

        this.selectFieldOptions.language = createOptions(selectOptions.language);

        this.selectFieldOptions.dialect = createOptions(selectOptions.dialect);

        this.selectFieldOptions.caseSignificance = createOptions(selectOptions.case);

        this.selectFieldOptions.acceptability = createOptions(selectOptions.acceptability);

        this.selectFieldOptions.state = [
            {value: "Active", label: "Active"},
            {value: "Inactive", label: "Inactive"}
        ];
    };

    ConceptViewer.prototype.validateEditForm = function () {

        //var parent = $("#komet_create_concept_parent_display_" + this.viewerID);
        //var description = $("#komet_create_concept_description_" + this.viewerID);
        var hasErrors = false;

        //if (parent.val() == undefined || parent.val() == ""){
        //
        //    $("#komet_create_concept_parent_fields_" + this.viewerID).after(UIHelper.generateFormErrorMessage("The Parent field must be filled in."));
        //    hasErrors = true;
        //}
        //
        //if (description.val() == undefined || description.val() == ""){
        //
        //    description.after(UIHelper.generateFormErrorMessage("The Description field must be filled in."));
        //    hasErrors = true;
        //}

        return hasErrors;
    }

    ConceptViewer.prototype.showSaveSection = function (sectionName) {

        var saveSection = $("#komet_concept_save_section_" + this.viewerID);
        var confirmSection = $("#komet_concept_confirm_section_" + this.viewerID);
        var createSection = $("#komet_concept_editor_section_" + this.viewerID);

        $("#komet_create_concept_form_" + this.viewerID).find(".komet-form-error, .komet-form-field-error").remove();

        if (sectionName == 'confirm'){

            var hasErrors = false;

            if (this.viewerAction == ConceptsModule.CREATE){
                hasErrors = this.validateCreateForm();
            } else {
                hasErrors = this.validateEditForm();
            }

            if (hasErrors){

                createSection.prepend(UIHelper.generateFormErrorMessage("Please fix the errors below."));
                return false;
            }

            console.log(UIHelper.hasFormChanged(createSection, true, true));
            saveSection.toggleClass("hide");
            confirmSection.toggleClass("hide");

        } else {

            saveSection.toggleClass("hide");
            confirmSection.toggleClass("hide");
            UIHelper.toggleChangeHighlights(createSection, false);
        }
    };

    ConceptViewer.prototype.cancelAction = function(previous_type, previous_id){


        if (previous_type && previous_id){

            if (previous_type == "ConceptViewer"){
                $.publish(KometChannels.Taxonomy.taxonomyTreeNodeSelectedChannel, ["", previous_id, TaxonomyModule.getStatedView(), this.viewerID, WindowManager.INLINE]);

            } else if (previous_type == "MappingViewer"){
                $.publish(KometChannels.Mapping.mappingTreeNodeSelectedChannel, ["", previous_id, this.viewerID, WindowManager.INLINE]);
            }
            WindowManager.closeViewer(this.viewerID);
            return false;
        }


    };

    // call our constructor function
    this.init(viewerID, currentConceptID, viewerAction)
};
