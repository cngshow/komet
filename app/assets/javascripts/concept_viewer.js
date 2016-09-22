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
    
var ConceptViewer = function(viewerID, currentConceptID) {

    ConceptViewer.prototype.init = function(viewerID, currentConceptID) {

        this.viewerID = viewerID;
        this.currentConceptID = currentConceptID;
        this.panelStates = {};
        this.trees = {};
        this.PARENTS_TREE = "concept_lineage_parents_tree_" + viewerID;
        this.CHILDREN_TREE = "concept_lineage_children_tree_" + viewerID;
        this.refsetGridOptions;
        this.REFSET_GRID = "refsets_grid_" + viewerID;

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

    ConceptViewer.prototype.editConcept = function(viewerID,stated){

        var divtext = "";
        var rowCount = 0;
        var partial = 'komet_dashboard/concept_edit';
        var concept_id  = "?concept_id=" + this.currentConceptID + "&stated=stated&partial=" + partial + "&viewer_id=" + viewerID;
        $.get( gon.routes.taxonomy_get_attributes_jsonreturntype_path  + concept_id     ,function( data ) {
            selectItemByValue(document.getElementById('komet_concept_Status'),data[1].value);

            if ( data[2].value == 'Primitive')
            {
                divtext = "<div class='komet-tree-node-icon komet-tree-node-primitive' title=''" + data[2].value + "'></div>"
            }
              else
            {
                divtext = "<div class='komet-tree-node-icon komet-tree-node-defined' title='" + data[2].value + "'></div>"
            }
            $("#definedDiv").html(divtext);

            selectItemByValue(document.getElementById('komet_concept_defined'),data[2].value);

        });
        descriptiondropdown();
        $.get( gon.routes.taxonomy_get_descriptions_jsonreturntype_path  + concept_id , function( descriptionData ) {

            $.each(descriptionData, function (index, value) {
                rowCount = rowCount + 1;
                 addDescriptionData(index,value,rowCount)
            });

        });


        // setup the assemblage field autocomplete functionality
        $("#taxonomy_lineage_display").autocomplete({
            source: gon.routes.search_get_assemblage_suggestions_path,
            minLength: 3,
            select: onLineageSuggestionSelection,
            change: onLineageSuggestionChange
        });

        // load any previous assemblage queries into a menu for the user to select from
        loadLineageRecents();

    };
    ConceptViewer.prototype.showHideConceptBtn = function (divname)    {
        if (divname == 'yesnolDiv')
        {
            $("#yesnolDiv").show();
            $("#savecancelDiv").hide();
        }
        else
        {
            $("#yesnolDiv").hide();
            $("#savecancelDiv").show();
        }


    }
    ConceptViewer.prototype.saveConcept = function()    {
        var preferredTerm = $("#taxonomy_pn_text").html();
        var fsn = $("#taxonomy_fsn_text").html();
        var parentConceptIds = $("#taxonomy_lineage_id").val();

        params = {fsn: fsn , preferredTerm: preferredTerm ,parentConceptIds:parentConceptIds} ;

        $.get( gon.routes.taxonomy_process_concept_Create_path , params, function( results ) {
            console.log(results);
        });
    }

    ConceptViewer.prototype.createConcept = function(viewerID){
        $("#yesnolDiv").hide();
        $("#txtDescription").keyup(function(event) {
            var stt = $(this).val();
            $("#taxonomy_pn_text").html(stt);

        });

        $("#taxonomy_lineage_display").keyup(function(event) {
            var stt =  $("#taxonomy_pn_text").html() + ' (' + $(this).val() + ')';
            $("#taxonomy_fsn_text").html(stt);
        });


        // setup the assemblage field autocomplete functionality
        $("#taxonomy_lineage_display").autocomplete({
            source: gon.routes.search_get_assemblage_suggestions_path,
            minLength: 3,
            select: onLineageSuggestionSelection,
            change: onLineageSuggestionChange
        });

        // load any previous assemblage queries into a menu for the user to select from
        loadLineageRecents();
        return true;
    };


    function selectItemByValue(elmnt, value){
        for(var i=0; i < elmnt.options.length; i++)
        {
            if(elmnt.options[i].value.toUpperCase() == value)
                elmnt.selectedIndex = i;
        }
    }
    function descriptiondropdown()    {
        var headingtr = document.createElement("TR");
        headingtr.setAttribute("id", "descriptiondata");
        headingtr.setAttribute("style", "background-color: #4f80d9;color:white;text-align: center")
        document.getElementById('description_texttbl').appendChild(headingtr);

        var headingtd0 = document.createElement("TD");
        headingtd0.innerHTML ='Description Type';
        document.getElementById("descriptiondata").appendChild(headingtd0);

        var headingtd1 = document.createElement("TD");
        headingtd1.innerHTML ='Description Text';
        document.getElementById("descriptiondata").appendChild(headingtd1);

        var headingtd2 = document.createElement("TD");
        headingtd2.innerHTML ='Acceptability';
        document.getElementById("descriptiondata").appendChild(headingtd2);

        var headingtd3 = document.createElement("TD");
        headingtd3.innerHTML ='State';
        document.getElementById("descriptiondata").appendChild(headingtd3);

        var headingtd4 = document.createElement("TD");
        headingtd4.innerHTML ='Language';
        document.getElementById("descriptiondata").appendChild(headingtd4);

        var headingtd5 = document.createElement("TD");
        headingtd5.innerHTML ='Case';
        document.getElementById("descriptiondata").appendChild(headingtd5);

        var headingtd6 = document.createElement("TD");
        headingtd6.innerHTML ='Delete';
        document.getElementById("descriptiondata").appendChild(headingtd6);


    }

    function addDescriptionData(index,data,rowCount)    {
        if(index == "descriptions")
        {
            for (var i = 0, count = data.length; i < count; i++) {
                rowCount = rowCount + 1;

                var descriptionRow = document.createElement("tr");
                descriptionRow.setAttribute("id", "descriptiondata" + rowCount);

                var idCell = document.createElement("td");
                var descriptiontypeCell = document.createElement("td");
                var descriptiontextCell = document.createElement("td");
                var acceptabilityCell = document.createElement("td");
                var stateCell = document.createElement("td");
                var languageCell = document.createElement("td");
                var caseCell = document.createElement("td");
                var DeleteCell = document.createElement("td");
                descriptionRow.setAttribute("id", "tr" + rowCount);

                idCell.innerHTML = rowCount;
                descriptiontypeCell.innerHTML = decriptionType(rowCount,data[i].description_type_short);
               // console.log('descriptiontypeDDL' + rowCount);
                //selectItemByValue(document.getElementById('descriptiontypeDDL' + rowCount) ,data[i].description_type_short);
                descriptiontextCell.innerHTML = '<input name="descriptionText"  type="text" id="' + "descriptionText" + '~' + rowCount + '" width="20px"  value=" ' + data[i].text + ' "  />';
                acceptabilityCell.innerHTML = acceptabilityType(rowCount);
                stateCell.innerHTML = stateType(rowCount);
                languageCell.innerHTML = languagetype(rowCount);
                caseCell.innerHTML = casetype(rowCount);
                DeleteCell.innerHTML = '<a name="removeRow" onclick="PreferenceModule.deleteRefsetFieldRow(' + rowCount + ')">X</a>';

                //  descriptionRow.appendChild(idCell);
                descriptionRow.appendChild(descriptiontypeCell);
                descriptionRow.appendChild(descriptiontextCell);
                descriptionRow.appendChild(acceptabilityCell);
                descriptionRow.appendChild(stateCell);
                descriptionRow.appendChild(languageCell);
                descriptionRow.appendChild(caseCell);
                descriptionRow.appendChild(DeleteCell);

                $("#description_texttbl").append(descriptionRow)
            }
        }

    }

    function decriptionType(rowCount,selecteditem)    {
        var options = "";
        var descriptionTypeSelect = '<select style="width:100px" id="descriptiontypeDDL' + rowCount + '">';
        if(selecteditem == 'SYN') {
            options += '<option SELECTED="SELECTED" value=SYN>SYN</option>';
        }
        if(selecteditem == 'FSN') {
            options += '<option SELECTED="SELECTED" value=FSN>FSN</option>';
        }
        descriptionTypeSelect += options + '</select>';
      return descriptionTypeSelect
    }
    function languagetype(rowCount)    {
        var options = "";
        var languagetypeSelect = '<select style="width:100px" id="languagetypeDDL">';
        options += '<option value=US English>US English</option>';
        options += '<option value=GB English>GB English</option>';
        languagetypeSelect += options + '</select>';
        return languagetypeSelect

    }
    function casetype()    {
        var options = "";
        var descriptionTypeSelect = '<select style="width:100px" id="descriptiontypeDDL">';
        options += '<option value=true>Yes</option>';
        options += '<option value=false>No</option>';
        descriptionTypeSelect += options + '</select>';
        return descriptionTypeSelect
    }
    function stateType()    {
        var options = "";
        var stateTypeSelect = '<select style="width:100px" id="descriptiontypeDDL">';
        options += '<option value=ACTIVE>Active</option>';
        options += '<option value=INACTIVE>InActive</option>';
        stateTypeSelect += options + '</select>';
        return stateTypeSelect
    }
    function acceptabilityType()    {
        var options = "";
        var acceptabilitySelect = '<select style="width:100px" id="acceptabilityDDL">';
        options += '<option value=Acceptable>Acceptable</option>';
        acceptabilitySelect += options + '</select>';
        return acceptabilitySelect
    }

    function onLineageSuggestionSelection(event, ui){

        $("#taxonomy_lineage_display").val(ui.item.label);
        $("#taxonomy_lineage_id").val(ui.item.value);
        var stt =  $("#taxonomy_pn_text").text() + ' (' + $("#taxonomy_lineage_display").val() + ')';
        $("#taxonomy_fsn_text").html(stt);
        return false;
    }

    function onLineageSuggestionChange(event, ui){

        if (!ui.item){
            event.target.value = "";
            $("#taxonomy_lineage_id").val("");

        }
    }
    function loadLineageRecents() {

        $.get(gon.routes.search_get_assemblage_recents_path, function (data) {

            var options = "";

            $.each(data, function (index, value) {

                // use the html function to escape any html that may have been entered by the user
                var valueText = $("<li>").text(value.text).html();
                options += "<li><a href=\"#\" onclick=\"TaxonomySearchModule.useLineageRecent('" + value.id + "', '" + valueText + "')\">" + valueText + "</a></li>";
            });

            $("#taxonomy_lineage_recents").html(options);
        });
    }

    function useLineageRecent(id, text){

        $("#taxonomy_lineage_display").val(text);
        $("#taxonomy_lineage_id").val(id);
    }

    // call our constructor function
    this.init(viewerID, currentConceptID)
};
