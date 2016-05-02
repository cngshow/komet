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
        
        //this.subscribeToTaxonomyTree();
        //this.subscribeToSearch();
    };

    ConceptViewer.prototype.togglePanelDetails = function(panelID, callback, preserveState) {

        // get the panel's expander icon, or all expander icons if this is the top level expander
        var expander = $("#" + panelID + " .glyphicon-plus-sign, #" + panelID + " .glyphicon-minus-sign");
        var drawer = $("#" + panelID + " .komet-concept-section-panel-details");
        var topLevelExpander = expander.parent().hasClass('komet-concept-body-tools');

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
                console.log("********* Restoring Open Pane ********");
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
        this.trees[this.CHILDREN_TREE] = new KometTaxonomyTree(this.CHILDREN_TREE, stated, false, this.currentConceptID, false, this.viewerID);

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

    ConceptViewer.prototype.subscribeToTaxonomyTree = function() {

        // listen for the onChange event broadcast by any of the taxonomy this.trees.
        $.subscribe(KometChannels.Taxonomy.taxonomyTreeNodeSelectedChannel, function (e, treeID, conceptID) {

            this.currentConceptID = conceptID;
            ConceptsModule.loadViewerData();
        });
    };

    ConceptViewer.prototype.subscribeToSearch = function() {

        // listen for the onChange event broadcast by selecting a search result.
        $.subscribe(KometChannels.Taxonomy.taxonomySearchResultSelectedChannel, function (e, conceptID) {

            this.currentConceptID = conceptID;
            this.trees[this.PARENTS_TREE].selectedConceptID = this.currentConceptID;
            this.trees[this.CHILDREN_TREE].selectedConceptID = this.currentConceptID;
            ConceptsModule.loadViewerData();
        });
    };

    ConceptViewer.prototype.loadConceptTabs = function() {

        // the path to a javascript partial file that will re-render all the appropriate partials once the ajax call returns
        var partial = 'komet_dashboard/concept_detail/load_tabs';

        // make an ajax call to get the concept for the current concept and pass it the currently selected concept id and the name of a partial file to render
        $.get(gon.routes.taxonomy_get_concept_information_path, {concept_id: this.currentConceptID, partial: partial}, function (data) {
        });
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
    ConceptViewer.prototype.linkToTaxonomyTree = function() {

        TaxonomyModule.tree.findNodeInTree(
            this.currentConceptID,
            $('#komet_concept_stated_inferred_' + this.viewerID)[0].value,
            function (foundNodeId) {
                console.log('Linked - taxonomy tree node ID: ' + foundNodeId);
            },
            true
        );
    };

    // call our constructor function
    this.init(viewerID, currentConceptID)
};
