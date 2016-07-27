/*
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

var TaxonomyModule = (function () {

    var linkedViewerID;
    var nestedSplitters;
    var hasNestedSplitters = false;

    function init() {

        this.defaultStatedView = $("#komet_taxonomy_stated_inferred")[0].value;

        this.tree = new KometTaxonomyTree("taxonomy_tree", this.defaultStatedView, false, null, true, WindowManager.NEW);
    }

    // listen for the onChange event broadcast by the trees on the details panes. If they have items selected then reload this tree
    function subscribeToDetailsTaxonomyTrees() {

        $.subscribe(KometChannels.Taxonomy.taxonomyTreeRebaseChannel, function (e, treeID, conceptID) {
            this.tree.rebaseTreeAtConcept("taxonomy_tree", conceptID);
        });
    }

    // listen for the onChange event broadcast by the trees on the details panes. If they have items selected then reload this tree
    function onDoubleClick(event) {
        reloadTree(TaxonomyModule[event.currentTarget.id].selectedConceptID);
    }

    function nestedSplittersExist(){

        nestedSplitters = $("#komet_east_pane_splitter_1");
        hasNestedSplitters = nestedSplitters.find(".splitter_bar").length > 0;
    }

    function refreshSplitters(){

        if (hasNestedSplitters){
            nestedSplitters.enhsplitter('refresh');
        }
    }

    function getStatedView(){
        return $("#komet_taxonomy_stated_inferred")[0].value;
    };

    return {
        initialize: init,
        nestedSplittersExist: nestedSplittersExist,
        refreshSplitters: refreshSplitters,
        getStatedView: getStatedView
    };

})();

