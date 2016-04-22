var TaxonomyModule = (function () {

    // COMMON TAXONOMY TREE FUNCTIONS (ALL TREES)

    function buildTaxonomyTree(tree_id, stated, parent_search, starting_concept_id, select_item) {

        var getParameters =  function (node) {

            var nodeToLoad;
            var params = null;

            if (node.id !== "#") {
                nodeToLoad = node.original.concept_id;
            } else {
                nodeToLoad = node.id;
            }

            if (!(((starting_concept_id === undefined) || (starting_concept_id === null)))) {
                nodeToLoad = starting_concept_id;
            }

            if (node.id === "#") {
                params =  {
                    'concept_id': nodeToLoad,
                    'parent_search': parent_search,
                    'parent_reversed': parent_search,
                    'stated': stated,
                    'starting_concept_id': starting_concept_id
                };
            } else {
                params = {
                    'concept_id': nodeToLoad,
                    'parent_search': node.original.parent_search,
                    'parent_reversed': node.original.parent_reversed,
                    'stated': stated,
                    'starting_concept_id': starting_concept_id
                };
            }

            params.starting_concept_id = starting_concept_id;
            starting_concept_id = null;

            return params;
        };

        //set ui to hour glass
        Common.cursor_wait();

        if (parent_search === undefined || parent_search === null) {
            parent_search = false;
        }

        if (stated === undefined || stated === null) {
            stated = 'true';
        }

        // select_item tells the tree if it should select the first item when the data is loaded
        if (select_item === undefined || select_item === null) {
            select_item = false;
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
        if (parent_search) {
            settings.core["strings"] = {"Loading ...": "<div class='komet-reverse-tree-node'>Loading ...</div>"};
        }

        var tree = $("#" + tree_id).jstree(settings);
        tree.parent_search = parent_search;
        tree.starting_concept_id = starting_concept_id;
        tree.select_item = select_item;
        tree.on('after_open.jstree', onAfterOpen);
        tree.on('after_close.jstree', onAfterClose);
        tree.on('changed.jstree', onChanged);
        tree.bind('dblclick', onDoubleClick);
        TaxonomyModule[tree_id] = tree;

        // set the tree to select the first node when it finishes loading
        TaxonomyModule[tree_id].bind('ready.jstree', function (event, data) {

            if (select_item) {
                data.instance.select_node('ul > li:first');
            }

            // set ui to regular cursor
            Common.cursor_auto();
        });
    }

    function onAfterOpen(node, selected) {
        //publish what we expect our observers to need in a way that allows them not to understand
        //our tree and our tree's dom.
        $.publish(KometChannels.Taxonomy.taxonomyTreeNodeOpenedChannel, selected.node.original.concept_id);

    }

    function onAfterClose(node, selected) {
        $.publish(KometChannels.Taxonomy.taxonomyTreeNodeClosedChannel, selected.node.original.concept_id);
    }

    function onChanged(event, selectedObject) {

        var conceptID = selectedObject.node.original.concept_id;
        var treeID = event.currentTarget.id;

        TaxonomyModule[treeID].selectedConceptID = conceptID;

        $.publish(KometChannels.Taxonomy.taxonomyTreeNodeSelectedChannel, [treeID, conceptID]);
    }

    // listen for the onChange event broadcast by the trees on the details panes. If they have items selected then reload this tree
    function onDoubleClick(event) {
        reloadTree(TaxonomyModule[event.currentTarget.id].selectedConceptID);
    }

    // destroy the current tree and reload it using the specified stated view
    function reloadTreeStatedView(treeID, stated) {

        var parent_search = TaxonomyModule[treeID].parent_search;
        var starting_concept_id = TaxonomyModule[treeID].starting_concept_id;
        var select_item = TaxonomyModule[treeID].select_item;

        TaxonomyModule[treeID].jstree(true).destroy();
        buildTaxonomyTree(treeID, stated, parent_search, starting_concept_id, select_item);
    }

    // destroy the current tree and reload it using the conceptID as a starting point
    function rebaseTreeAtConcept(treeID, conceptID, stated) {

        TaxonomyModule[treeID].jstree(true).destroy();
        buildTaxonomyTree(treeID, stated, false, conceptID, true);
    }

    function getNodeIDByConceptID(treeID, conceptID){

        var treeModel = TaxonomyModule[treeID].jstree(true)._model.data;
        var nodeID;

        for (var modelNode in treeModel){

            if (treeModel.hasOwnProperty(modelNode) && modelNode !== '#' && treeModel[modelNode].original.concept_id && treeModel[modelNode].original.concept_id === conceptID) {
                nodeID = treeModel[modelNode].id;
                break;
            }
        }

        return nodeID;
    }

    /*
    * findNodeInTree - find the target node in the tree, populating its lineage path if it is not currently in the tree
    * @param treeID - the name of the tree to perform the action on
    * @param conceptID - the concept ID for the target node
    * @param stated - is the target concept using stated or inferred view
    * @param returnFunction - a callback function that takes as a parameter the tree node ID of the target node. Because findNodeInTree may be making ajax calls it can't return the ID normally
    * @param selectTheNode - should the target node be selected once it is found (default true)
    * @param suppressChangeEvent - should the tree onchange event be fired if the target node is selected (default true)
    */
    function findNodeInTree(treeID, conceptID, stated, returnFunction, selectTheNode, suppressChangeEvent) {

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
        var nodeID = getNodeIDByConceptID(treeID, conceptID);

        // if the node exists in the tree continue on
        if (nodeID == undefined){

            var params = '?parent_search=true&parent_reversed=true&tree_walk_levels=100&concept_id=' + conceptID + '&stated=' + stated;

            // make a call to get all the parents of the target node back to the root
            $.get(gon.routes.taxonomy_load_tree_data_path + params, function (data) {

                if (data.length > 0){

                    var tree = TaxonomyModule[treeID].jstree(true);

                    // this is a recursive function that will process each of the returned nodes, starting with the root, and walk down to the target node
                    var reverseTreeWalk = function(node){

                        // get find this node in the tree
                        var nodeInTree = tree.get_node(getNodeIDByConceptID(treeID, node.concept_id));

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

                            // open this node in the tree so we get all of its children
                            tree.open_node(nodeInTree, function(){

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
                                    nodeID = tree.get_node(getNodeIDByConceptID(treeID, conceptID)).id;

                                    // resolve our deferred call with the tree id of the target node
                                    deferredReturn.resolve(nodeID);

                                    // back down our callback array to clean up all the nodes that were touched
                                    while (cleanUpNodes.length > 0){
                                        cleanUpNodes.pop().call();
                                    }
                                }
                            });
                        }
                    };

                    // call the recursive function with the root node
                    reverseTreeWalk(data[data.length - 1]);
                }
            });
        } else{

            // the node was already in the tree so resolve our deferred call with its tree ID
            deferredReturn.resolve(nodeID);
        }

        // what to do once our target node has been found
        $.when(deferredReturn).done(function(data){

            // if the node ID was found and we are selecting the target
            if (data != undefined && selectTheNode){

                // select the target node without firing the change event and set the concept ID as the current ID on the tree
                selectNode(treeID, nodeID, suppressChangeEvent);
                TaxonomyModule[treeID].selectedConceptID = conceptID;
            }

            // put the target node ID into the return callback so the calling function has access to it
            returnFunction(data);
        });
    }

    function selectNode(treeID, nodeID, suppressChangeEvent){

        var tree = TaxonomyModule[treeID].jstree(true);

        tree.deselect_all(true);
        tree._open_to(nodeID);
        tree.select_node(nodeID, suppressChangeEvent, false);
    }

    // MAIN TAXONOMY TREE FUNCTIONS

    // listen for the onChange event broadcast by the trees on the details panes. If they have items selected then reload this tree
    function subscribeToDetailsTaxonomyTrees() {

        $.subscribe(KometChannels.Taxonomy.taxonomyTreeRebaseChannel, function (e, treeID, conceptID) {
            rebaseTreeAtConcept("taxonomy_tree", conceptID);
        });
    }

    function init() {

        this.tree = new KometTaxonomyTree("taxonomy_tree", $("#komet_taxonomy_stated_inferred")[0].value, false, null, true);
    }

    return {
        initialize: init,
        buildTaxonomyTree: buildTaxonomyTree,
        reloadTreeStatedView: reloadTreeStatedView,
        findNodeInTree: findNodeInTree,
        selectNode: selectNode
    };

})();
