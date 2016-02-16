var TaxonomyModule = (function () {

    function buildTaxonomyTree(tree_id, parent_search, starting_concept_id, select_item) {

        //set ui to hour glass
        Common.cursor_wait();

        if (parent_search === undefined || parent_search === null){
            parent_search = false;
        }

        if (select_item === undefined || select_item === null){
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

                        var nodeToLoad;

                        if (node.id !== "#"){
                            //todo Tim used to be node.original.concept_id, but this is nil.
                            nodeToLoad = node.original.id;
                        } else {
                            nodeToLoad = node.id;
                        }

                        if (!(((starting_concept_id === undefined) || (starting_concept_id === null)))){
                            nodeToLoad = starting_concept_id;
                        }

                        starting_concept_id = null;

                        if (node.id === "#"){
                            return {'concept_id': nodeToLoad, 'parent_search': parent_search, 'parent_reversed': parent_search};
                        } else {
                            return  {'concept_id': nodeToLoad, 'parent_search': node.original.parent_search, 'parent_reversed': node.original.parent_reversed};
                        }
                    }
                }
            }
        };
        var tree = $("#" + tree_id).jstree(settings);
        tree.on('after_open.jstree', onAfterOpen);
        tree.on('after_close.jstree', onAfterClose);
        tree.on('changed.jstree', onChanged);
        tree.bind('dblclick', onDoubleClick);
        TaxonomyModule[tree_id + ''] = tree;

        // set the tree to select the first node when it finishes loading
        TaxonomyModule[tree_id + ''].bind('ready.jstree', function(event, data) {

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
        $.publish(EtsChannels.Taxonomy.taxonomyTreeNodeOpenedChannel,selected.node.original.concept_id);

    }

    function onAfterClose(node, selected) {
        $.publish(EtsChannels.Taxonomy.taxonomyTreeNodeClosedChannel,selected.node.original.concept_id);
    }

    function onChanged(event, selectedObject) {

        var conceptId = selectedObject.node.original.concept_id;

        TaxonomyModule.selectedTreeNode = conceptId;

        $.publish(EtsChannels.Taxonomy.taxonomyTreeNodeSelectedChannel, conceptId);
    }

    // listen for the onChange event broadcast by the trees on the details panes. If they have items selected then reload this tree
    function onDoubleClick(event) {
        reloadTree(TaxonomyModule.selectedTreeNode);
    }

    // destroy the current tree and reload it using the conceptID as a starting point
    function reloadTree(conceptID) {

        TaxonomyModule.taxonomy_tree.jstree(true).destroy();
        buildTaxonomyTree("taxonomy_tree", false, conceptID, true);
    }

    // listen for the onChange event broadcast by the trees on the details panes. If they have items selected then reload this tree
    function subscribeToDetailsTaxonomyTrees() {

        $.subscribe(EtsChannels.Taxonomy.taxonomyTreeNodeSelectedChannel, function (e, conceptID) {
            reloadTree(conceptID);
        });
    }

    function init(tree_id, parent_search, starting_concept_id, select_item) {

        buildTaxonomyTree(tree_id, parent_search, starting_concept_id, select_item);
    }

    return {
        initialize : init,
        buildTaxonomyTree: buildTaxonomyTree
    };

})();
