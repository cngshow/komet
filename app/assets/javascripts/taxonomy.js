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
        this.tree = new KometTaxonomyTree("taxonomy_tree", getViewParams(), false, null, true, null);
    }

    function getStatedView(){
        return $("#komet_taxonomy_stated").prop("checked");
    }

    function toggleStatedView(statedField){
        statedField.parent().toggleClass("btn-primary btn-default");
    }

    function getViewParams (){
        return {stated: getStatedView()};
    }

    function reloadTree() {

        var selectedID = null;
        var linkedViewerID = WindowManager.getLinkedViewerID();

        if (linkedViewerID != null && linkedViewerID != WindowManager.NEW && WindowManager.viewers[linkedViewerID].currentConceptID){
            selectedID = WindowManager.viewers[linkedViewerID].currentConceptID;
        }

        this.tree.reloadTree(getViewParams(), false);
    }

    return {
        initialize: init,
        getStatedView: getStatedView,
        toggleStatedView: toggleStatedView,
        getViewParams: getViewParams,
        reloadTree: reloadTree
    };

})();

