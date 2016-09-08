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

var KometMappingTree = function(treeID, windowType){

    KometMappingTree.prototype.init = function(treeID, windowType){

        this.treeID = treeID;
        this.windowType = windowType;

        this.buildMappingTree();
    };

    KometMappingTree.prototype.buildMappingTree = function(selectItem) {

        if (selectItem == null){
            selectItem = true;
        }

        //set ui to hour glass
        Common.cursor_wait();

        var settings = {
            "core": {
                "animation": 0,
                "check_callback": true,
                "themes": {"stripes": true},
                'data': {
                    'url': gon.routes.mapping_load_tree_data_path,
                    'data': function (node) {
                        return getParameters(node);
                    }
                }
            }
        };

        var getParameters = function(node) {

            var params = null;

            if (node.id !== "#") {
                params = {'set_id': node.original.set_id};
            } else {
                params = {'set_id': node.id};
            }

            params.text_filter = $("#komet_mapping_tree_text_filter")[0].value;
            params.set_filter = $("#komet_mapping_tree_set_filter")[0].value;

            return params;
        }.bind(this);
        
        this.tree = $("#" + this.treeID).jstree(settings);
        this.tree.on('changed.jstree', onChanged.bind(this));

        // set the tree to select the first node when it finishes loading based on the value of selectItem
        this.tree.bind('ready.jstree', function (event, data) {

            if (selectItem){
                data.instance.select_node('ul > li:first');
            }

            // set ui to regular cursor
            Common.cursor_auto();
        }.bind(this));


        function onChanged(event, selectedObject) {

            var setID = selectedObject.node.original.set_id;
            var viewerID = WindowManager.getLinkedViewerID();
            var viewer = this.tree.parents("div[id^=komet_viewer_]");

            if (viewer.length > 0){
                viewerID = viewer.first().attr("data-komet-viewer-id");
            }

            this.selectedSetID = setID;

            $.publish(KometChannels.Mapping.mappingTreeNodeSelectedChannel, [this.treeID, setID, viewerID, this.windowType]);
        }
    };

    // destroy the current tree and reload it
    KometMappingTree.prototype.reloadTree = function(selectItem, setID) {

        if (selectItem == null){
            selectItem = false;
        }
        this.tree.jstree(true).destroy();
        this.buildMappingTree(selectItem);

        if (setID != null){
            this.findNodeInTree(setID, true, false)
        }
    };

    KometMappingTree.prototype.getNodeIDBySetID = function(setID){

        var treeModel = this.tree.jstree(true)._model.data;
        var nodeID;

        for (var modelNode in treeModel){

            if (treeModel.hasOwnProperty(modelNode) && modelNode !== '#' && treeModel[modelNode].original.set_id && treeModel[modelNode].original.set_id === setID) {
                nodeID = treeModel[modelNode].id;
                break;
            }
        }

        return nodeID;
    };

    /*
     * findNodeInTree - find the target node in the tree, populating its lineage path if it is not currently in the tree
     * @param setID - the set ID for the target node
     * @param selectTheNode - should the target node be selected once it is found (default true)
     * @param suppressChangeEvent - should the tree onchange event be fired if the target node is selected (default true)
     */
    KometMappingTree.prototype.findNodeInTree = function(setID, selectTheNode, suppressChangeEvent) {

        if (selectTheNode == undefined){
            selectTheNode = true;
        }

        if (suppressChangeEvent == undefined){
            suppressChangeEvent = true;
        }

        // get the ID of the node in the tree from the concept ID
        var nodeID = this.getNodeIDBySetID(setID);

        // if the node exists in the tree continue on
        if (nodeID != undefined){

            // if the node ID was found and we are selecting the target
            if (selectTheNode){

                // select the target node without firing the change event and set the concept ID as the current ID on the tree
                this.selectNode(nodeID, suppressChangeEvent);
                this.selectedSetID = setID;
            }

            // return the target node ID so the calling function has access to it
            return nodeID;
        }
    };

    KometMappingTree.prototype.selectNode = function(nodeID, suppressChangeEvent){

        var tree = this.tree.jstree(true);

        tree.deselect_all(true);
        tree._open_to(nodeID);
        tree.select_node(nodeID, suppressChangeEvent, false);

        var node = $("#" + nodeID + "_anchor");
        node.scrollParent()[0].scrollTop = node.position().top;

    };

    // call our constructor function
    this.init(treeID, windowType);
};
