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

    function getStampDate(){

        var stamp_date = $("#komet_taxonomy_tree_stamp_date").find("input").val();

        if (stamp_date == '' || stamp_date == 'latest') {
            return 'latest';
        } else {
            return new Date(stamp_date).getTime().toString();
        }
    };

    // function to set the initial state of the view param fields
    function initViewParams(view_params) {

        // get the stated field group
        var stated = $("#komet_taxonomy_panel").find("input[name='komet_taxonomy_stated_inferred']");

        // initialize the stated field
        UIHelper.initStatedField(stated, view_params.stated);

        // initialize the STAMP date field
        UIHelper.initDatePicker("#komet_taxonomy_tree_stamp_date", view_params.time);

    }

    function getViewParams (){
        return {stated: getStatedView(), time: getStampDate()};
    }

    // function to change the view param values and then reload the tree
    function setViewParams(view_params) {

        // set the stated field
        UIHelper.setStatedField($("#komet_taxonomy_panel").find("input[name='komet_taxonomy_stated_inferred']"), view_params.stated);

        // set the STAMP date field
        UIHelper.setStampDate($("#komet_taxonomy_tree_stamp_date"), view_params.time);

        // reload the tree
        this.reloadTree();
    }

    function reloadTree() {

        var selectedID = null;
        var linkedViewerID = WindowManager.getLinkedViewerID();

        // if there is a linked concept viewer get its concept ID to try to find the node and select it again after reload, without triggering the change event
        if (linkedViewerID != null && linkedViewerID != WindowManager.NEW && WindowManager.viewers[linkedViewerID].currentConceptID){
            selectedID = WindowManager.viewers[linkedViewerID].currentConceptID;
        }

        // reload the tree, trying to reselect a linked concept if there was one
        this.tree.reloadTree(getViewParams(), false, selectedID);
    }

    return {
        initialize: init,
        getStatedView: getStatedView,
        getStampDate: getStampDate,
        initViewParams: initViewParams,
        getViewParams: getViewParams,
        setViewParams: setViewParams,
        reloadTree: reloadTree
    };

})();

