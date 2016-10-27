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

    function init() {

        this.defaultStatedView = this.getStatedView();

        this.tree = new KometTaxonomyTree("taxonomy_tree", this.defaultStatedView, false, null, true, null);
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

    function getStatedView(){
        return $("#komet_taxonomy_stated").prop("checked");
    }

    function setStatedView(field){
        this.tree.reloadTreeStatedView(field.value);
    }

    return {
        initialize: init,
        getStatedView: getStatedView,
        setStatedView: setStatedView
    };

})();

