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

var KometTaxonomyTree = function(treeID, stated, parentSearch, startingConceptID, selectItem, viewerID){

    KometTaxonomyTree.prototype.init = function(treeID, stated, parentSearch, startingConceptID, selectItem, viewerID){

        this.treeID = treeID;
        this.viewerID = viewerID;

        this.buildTaxonomyTree(stated, parentSearch, startingConceptID, selectItem);
    };

    KometTaxonomyTree.prototype.buildTaxonomyTree = function(stated, parentSearch, startingConceptID, selectItem) {

        var getParameters = function(node) {

            var nodeToLoad;
            var params = null;

            if (node.id !== "#") {
                nodeToLoad = node.original.concept_id;
            } else {
                nodeToLoad = node.id;
            }

            if (startingConceptID !== undefined && startingConceptID !== null) {
                nodeToLoad = startingConceptID;
            }

            if (node.id === "#") {
                params =  {
                    'concept_id': nodeToLoad,
                    'parent_search': parentSearch,
                    'parent_reversed': parentSearch,
                    'stated': stated,
                    'starting_concept_id': startingConceptID
                };
            } else {
                params = {
                    'concept_id': nodeToLoad,
                    'parent_search': node.original.parent_search,
                    'parent_reversed': node.original.parent_reversed,
                    'stated': stated,
                    'starting_concept_id': startingConceptID
                };
            }

            params.starting_concept_id = startingConceptID;
            startingConceptID = null;

            return params;
        };

        //set ui to hour glass
        Common.cursor_wait();

        if (parentSearch === undefined || parentSearch === null) {
            parentSearch = false;
        }

        if (stated === undefined || stated === null) {
            stated = 'true';
        }

        // select_item tells the tree if it should select the first item when the data is loaded
        if (selectItem === undefined || selectItem === null) {
            selectItem = false;
        }

        var settings = {
            "core": {
                "animation": 0,
                "check_callback": true,
                "themes": {"stripes": true},
                'data': {
                    'url': gon.routes.taxonomy_load_tree_data_path,
                    'data': function (node) {
                        return getParameters(node);
                    }
                }
            }
        };

        // if this is a parent search make sure the loading text is oriented correctly.
        if (parentSearch) {
            settings.core["strings"] = {"Loading ...": "<div class='komet-reverse-tree-node'>Loading ...</div>"};
        }

        this.tree = $("#" + this.treeID).jstree(settings);
        this.parentSearch = parentSearch;
        this.startingConceptID = startingConceptID;
        this.selectItem = selectItem;
        this.stated = stated;
        this.tree.on('after_open.jstree', onAfterOpen);
        this.tree.on('after_close.jstree', onAfterClose);
        this.tree.on('changed.jstree', onChanged.bind(this));

        // set the tree to select the first node when it finishes loading
        this.tree.bind('ready.jstree', function (event, data) {

            if (selectItem) {
                data.instance.select_node('ul > li:first');
            }

            // set ui to regular cursor
            Common.cursor_auto();
        }.bind(this));

        function onAfterOpen(node, selected) {
            //publish what we expect our observers to need in a way that allows them not to understand
            //our tree and our tree's dom.
            $.publish(KometChannels.Taxonomy.taxonomyTreeNodeOpenedChannel, [this.treeID, selected.node.original.concept_id]);

        }

        function onAfterClose(node, selected) {
            $.publish(KometChannels.Taxonomy.taxonomyTreeNodeClosedChannel, [this.treeID, selected.node.original.concept_id]);
        }

        function onChanged(event, selectedObject) {

            var conceptID = selectedObject.node.original.concept_id;

            this.selectedConceptID = conceptID;

            $.publish(KometChannels.Taxonomy.taxonomyTreeNodeSelectedChannel, [this.treeID, conceptID, this.stated, this.viewerID]);
        }
    };

    // destroy the current tree and reload it using the specified stated view
    KometTaxonomyTree.prototype.reloadTreeStatedView = function(stated) {

        this.tree.jstree(true).destroy();
        this.buildTaxonomyTree(stated, this.parentSearch, this.startingConceptID, this.selectItem);
    };

    // destroy the current tree and reload it using the conceptID as a starting point
    KometTaxonomyTree.prototype.rebaseTreeAtConcept = function(conceptID, stated) {

        this.tree.jstree(true).destroy();
        this.buildTaxonomyTree(stated, false, conceptID, true);
    };

    KometTaxonomyTree.prototype.getNodeIDByConceptID = function(conceptID){

        var treeModel = this.tree.jstree(true)._model.data;
        var nodeID;

        for (var modelNode in treeModel){

            if (treeModel.hasOwnProperty(modelNode) && modelNode !== '#' && treeModel[modelNode].original.concept_id && treeModel[modelNode].original.concept_id === conceptID) {
                nodeID = treeModel[modelNode].id;
                break;
            }
        }

        return nodeID;
    };

    /*
     * findNodeInTree - find the target node in the tree, populating its lineage path if it is not currently in the tree
     * @param conceptID - the concept ID for the target node
     * @param stated - is the target concept using stated or inferred view
     * @param returnFunction - a callback function that takes as a parameter the tree node ID of the target node. Because findNodeInTree may be making ajax calls it can't return the ID normally
     * @param selectTheNode - should the target node be selected once it is found (default true)
     * @param suppressChangeEvent - should the tree onchange event be fired if the target node is selected (default true)
     */
    KometTaxonomyTree.prototype.findNodeInTree = function(conceptID, stated, returnFunction, selectTheNode, suppressChangeEvent) {

        // create a deferred object so that when the node is found we can return the node ID to the calling function
        var deferredReturn = $.Deferred();

        // an array of callback functions to handle cleanup of each node we touch once we find the target node
        var cleanUpNodes = [];

        if (selectTheNode == undefined){
            selectTheNode = true;
        }

        if (suppressChangeEvent == undefined){
            suppressChangeEvent = true;
        }

        if (returnFunction == undefined){
            returnFunction = function(){};
        }

        // get the ID of the node in the tree from the concept ID
        var nodeID = this.getNodeIDByConceptID(conceptID);

        // if the node exists in the tree continue on
        if (nodeID == undefined){

            var tree = this.tree.jstree(true);
            var params = '?parent_search=true&parent_reversed=true&tree_walk_levels=100&concept_id=' + conceptID + '&stated=' + stated;

            var processNodeParents = function(data){

                if (data.length > 0){

                    // this is a recursive function that will process each of the returned nodes, starting with the root, and walk down to the target node
                    var reverseTreeWalk = function(node){

                        // get find this node in the tree
                        var nodeInTree = tree.get_node(this.getNodeIDByConceptID(node.concept_id));

                        if (nodeInTree){

                            // store the open/close state of the node in the tree
                            var isAlreadyOpen = tree.is_open(nodeInTree);

                            // add a function to our callback array to handle cleanup of this node once the target node is found
                            cleanUpNodes.push(function(){

                                // if the node was closed and we are not selecting the target node, re-close this node
                                if (!selectTheNode && !isAlreadyOpen){
                                    tree.close_node(nodeInTree);
                                }
                            });

                            var processNodeChildren = function(){

                                // if the node has parents (which is actually a list of its children in the regular tree)
                                if (typeof node.parent !== 'undefined'){

                                    // look through the lineage nodes until you find the node referenced by this node's parent property (which is actually its child in the regular tree)
                                    var nextNode = data.find(function(arrayNode){
                                        return arrayNode.id == node.parent;
                                    });

                                    // call this function again using the child node
                                    reverseTreeWalk(nextNode);

                                } else{

                                    // since the node has no children it is the parent of our target node, so the target node should now exist in the tree.
                                    // get the target node by its concept ID
                                    nodeID = tree.get_node(this.getNodeIDByConceptID(conceptID)).id;

                                    // resolve our deferred call with the tree id of the target node
                                    deferredReturn.resolve(nodeID);

                                    // back down our callback array to clean up all the nodes that were touched
                                    while (cleanUpNodes.length > 0){
                                        cleanUpNodes.pop().call();
                                    }
                                }
                            }.bind(this);

                            // open this node in the tree so we get all of its children
                            tree.open_node(nodeInTree, processNodeChildren);
                        }
                    }.bind(this);

                    // call the recursive function with the root node
                    reverseTreeWalk(data[data.length - 1]);
                }
            }.bind(this);

            // make a call to get all the parents of the target node back to the root
            $.get(gon.routes.taxonomy_load_tree_data_path + params, processNodeParents);
        } else{

            // the node was already in the tree so resolve our deferred call with its tree ID
            deferredReturn.resolve(nodeID);
        }

        // what to do once our target node has been found
        $.when(deferredReturn).done(function(data){

            // if the node ID was found and we are selecting the target
            if (data != undefined && selectTheNode){

                // select the target node without firing the change event and set the concept ID as the current ID on the tree
                this.selectNode(nodeID, suppressChangeEvent);
                this.selectedConceptID = conceptID;
            }

            // put the target node ID into the return callback so the calling function has access to it
            returnFunction(data);
        }.bind(this));
    };

    KometTaxonomyTree.prototype.selectNode = function(nodeID, suppressChangeEvent){

        var tree = this.tree.jstree(true);

        tree.deselect_all(true);
        tree._open_to(nodeID);
        tree.select_node(nodeID, suppressChangeEvent, false);
    };

    // call our constructor function
    this.init(treeID, stated, parentSearch, startingConceptID, selectItem, viewerID);
};
