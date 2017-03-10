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

    function getAllowedStates (){
        return $("#komet_taxonomy_allowed_states").val();
    }

    function getStatedView(){
        return $("#komet_taxonomy_stated").val();
    }

    function getStampDate(){

        var stamp_date = $("#komet_taxonomy_tree_stamp_date").find("input").val();

        if (stamp_date == '' || stamp_date == 'latest') {
            return 'latest';
        } else {
            return new Date(stamp_date).getTime().toString();
        }
    };

    function getStampModules(){
        return $('#komet_taxonomy_stamp_module').val();
    }

    function getStampPath(){
        return $('#komet_taxonomy_stamp_path').val();
    }

    // function to set the initial state of the view param fields
    function initViewParams(view_params) {

        // initialize the STAMP date field
        UIHelper.initDatePicker("#komet_taxonomy_tree_stamp_date", view_params.time);
    }

    function getViewParams (){
        return {stated: getStatedView(), allowedStates: getAllowedStates(), time: getStampDate(), modules: getStampModules(), path: getStampPath()};
    }

    // function to change the view param values and then reload the tree
    function setViewParams(view_params) {

        // set the Allowed States field
        $("#komet_taxonomy_allowed_states").val(view_params.allowedStates);

        // set the stated field
        $("#komet_taxonomy_stated").val(view_params.stated);

        // set the STAMP date field
        UIHelper.setStampDate($("#komet_taxonomy_tree_stamp_date"), view_params.time);

        // set the modules field
        $("#komet_taxonomy_stamp_module").val(view_params.modules);

        // set the path field
        $("#komet_taxonomy_stamp_path").val(view_params.path);

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
        getAllowedStates: getAllowedStates,
        getStatedView: getStatedView,
        getStampDate: getStampDate,
        getStampModules: getStampModules,
        getStampPath: getStampPath,
        initViewParams: initViewParams,
        getViewParams: getViewParams,
        setViewParams: setViewParams,
        reloadTree: reloadTree
    };

})();

