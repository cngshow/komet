var TaxonomyModule = (function () {

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

            starting_concept_id = null;

            if (node.id === "#") {
                params =  {
                    'concept_id': nodeToLoad,
                    'parent_search': parent_search,
                    'parent_reversed': parent_search,
                    'stated': stated
                };
            } else {
                params = {
                    'concept_id': nodeToLoad,
                    'parent_search': node.original.parent_search,
                    'parent_reversed': node.original.parent_reversed,
                    'stated': stated
                };
            }

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
        TaxonomyModule[tree_id + ''] = tree;

        // set the tree to select the first node when it finishes loading
        TaxonomyModule[tree_id + ''].bind('ready.jstree', function (event, data) {

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

        var conceptId = selectedObject.node.original.concept_id;

        TaxonomyModule.selectedTreeNode = conceptId;

        $.publish(KometChannels.Taxonomy.taxonomyTreeNodeSelectedChannel, conceptId);
    }

    // listen for the onChange event broadcast by the trees on the details panes. If they have items selected then reload this tree
    function onDoubleClick(event) {
        reloadTree(TaxonomyModule.selectedTreeNode);
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
    function rebaseTreeAtConcept(conceptID, stated) {

        TaxonomyModule.taxonomy_tree.jstree(true).destroy();
        buildTaxonomyTree("taxonomy_tree", stated, false, conceptID, true);
    }

    // listen for the onChange event broadcast by the trees on the details panes. If they have items selected then reload this tree
    function subscribeToDetailsTaxonomyTrees() {

        $.subscribe(KometChannels.Taxonomy.taxonomyTreeNodeSelectedChannel, function (e, conceptID) {
            rebaseTreeAtConcept(conceptID);
        });
    }

    function init(tree_id, stated, parent_search, starting_concept_id, select_item) {

        buildTaxonomyTree(tree_id, stated, parent_search, starting_concept_id, select_item);
    }

    return {
        initialize: init,
        buildTaxonomyTree: buildTaxonomyTree,
        reloadTreeStatedView: reloadTreeStatedView
    };

})();
