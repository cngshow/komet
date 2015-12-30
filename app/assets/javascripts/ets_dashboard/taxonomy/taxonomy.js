var TaxonomyModule = (function () {

    function buildTaxonomyTree(tree_id, parent_search, starting_id) {

        if (parent_search == undefined || parent_search == null){
            parent_search = false;
        }

        var settings = {
            "core": {
                "animation": 0,
                "check_callback": true,
                "themes": {"stripes": true},
                'data': {
                    'url': gon.routes.taxonomy_load_tree_data_path,
                    'data': function (node) {

                        var nodeToLoad = node.id;

                        if (starting_id != null && nodeToLoad !== starting_id){
                            nodeToLoad = starting_id;
                        }

                        starting_id = null;

                        if (node.id == "#"){
                            return {'id': nodeToLoad, 'parent_search': parent_search, 'parent_reversed': parent_search};
                        } else {
                            return {'id': nodeToLoad, 'parent_search': node.original.parent_search, 'parent_reversed': node.original.parent_reversed};
                        }
                    }
                }
            }
        };
        var tree = $("#" + tree_id).jstree(settings);
        tree.on('after_open.jstree', onAfterOpen);
        tree.on('after_close.jstree', onAfterClose);
        tree.on('changed.jstree', onChanged);
        TaxonomyModule[tree_id + ''] = tree;
    }

    function onAfterOpen(node, selected) {
        //publish what we expect our observers to need in a way that allows them not to understand
        //our tree and our tree's dom.
        $.publish(EtsChannels.Taxonomy.taxonomyTreeNodeOpenedChannel,selected.node.id);

    }

    function onAfterClose(node, selected) {
        $.publish(EtsChannels.Taxonomy.taxonomyTreeNodeClosedChannel,selected.node.id);
    }

    function onChanged(event, selectedObject) {

        var conceptId = selectedObject.node.id;
        var parentConceptId = selectedObject.node.original.parent_id;

        var conceptText = selectedObject.node.text;

        TaxonomyModule.selectedTreeNode = conceptId;

        $.publish(EtsChannels.Taxonomy.taxonomyTreeNodeSelectedChannel, conceptId, conceptText);
    }

    function init(tree_id, parent_search, starting_id) {

        buildTaxonomyTree(tree_id, parent_search, starting_id);
    }

    return {
        initialize : init,
        buildTaxonomyTree: buildTaxonomyTree
    };

})();
