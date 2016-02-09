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
/*
var TaxonomyModule2 = (function () {
    var TreeDirection = {
        UP: 'tree-up',
        DOWN: 'tree-down'
    };

    function initializeEtsTree(div_id, direction) {
        alert('initializing the tree again - faster please...!vasdf another again asdas asdfasf adgfasdf');
        var tree_panel = $('<div>', {class: 'panel-body tree ' + direction});
        var root_ul = drawNodes([{id: "rootnode", text: "SNOMED CT"}]);
        tree_panel.html(root_ul);
        $(div_id).html(tree_panel);
        loadConceptNodes(true);
    }

    function loadConceptNodes() {
        var target = $(event.target);

        //the initial load will pass in true as the first argument to load snomed. All subsequent calls have no arguments
        if (arguments[0]) {
            target = $('button.root');
        }

        var open_up = target.closest('div.tree').hasClass(TaxonomyModule2.TreeDirection.UP);
        var node = target.closest('.treeNode');
        var conceptId = node.data('concept');
        var opening = true;
        var icon = null;

        //flip the target icon to open
        if (target.hasClass("glyphicon")) {
            opening = target.hasClass("glyphicon-chevron-right");
            icon = opening ? (open_up ? "glyphicon-chevron-up" : "glyphicon-chevron-down") : "glyphicon-chevron-right";
            target.removeClass("glyphicon-chevron-right glyphicon-chevron-down glyphicon-chevron-up");
            target.addClass(icon);
        }
        else {
            var img = target.find("i");
            opening = img.hasClass("glyphicon-chevron-right");
            icon = opening ? (open_up ? "glyphicon-chevron-up" : "glyphicon-chevron-down") : "glyphicon-chevron-right";
            target.html("<i class='glyphicon taxTreeBtn " + icon + "'></i>");
        }

        if (opening) {
            console.log("opening " + conceptId);
            $.get(gon.routes.taxonomy_load_data_path, {id: conceptId}, function (data) {
                ul_node = drawNodes(data);

                if (open_up) {
                    node.prepend(ul_node);
                } else {
                    node.append(ul_node);
                }
            });
        }
        else {
            $.publish(EtsChannels.Taxonomy.taxonomyTreeNodeClosedChannel, conceptId);
            node.find('ul:first').remove();
        }
        return false;
    }

    function drawNodes(data) {
        var ul = $('<ul>', {class: 'tree-ul'});

        for (var i = 0; i < data.length; i++) {
            var concept = data[i];
            var closed = $('<i>', {class: 'glyphicon glyphicon-chevron-right'});
            var li = $('<li>', {class: 'treeNode'}).attr("data-concept", concept.id);
            var bg = $('<div>', {class: 'btn-group'});
            var classnames = 'btn btn-link btn-xs taxTreeBtn ' + (concept.id === 'rootnode' ? 'root' : '');
            var jqBtn = $('<button>', {
                type: 'button',
                class: classnames,
                on: {
                    click: function (event) {
                        TaxonomyModule2.loadConceptNodes();
                    }
                }
            }).html(closed);
            var lbl = $('<button>', {
                type: 'button',
                class: 'btn btn-link btn-xs taxTreeLabel',
                text: concept.text,
                data: {
                    conceptId: concept.id
                },
                on: {
                    click: function (event) {
                        //publish the select action for our observers
                        $.publish(EtsChannels.Taxonomy.taxonomyTreeNodeSelectedChannel, $(event.currentTarget).data('conceptId'));
                    },
                    dblclick: function (event) {
                        console.log('double clicked! ' + $(event.currentTarget).data('conceptId'));
                    }
                }
            });

            //build the button group to display the button and label and add it to the li and ul for the tree display
            bg.append(jqBtn).append(lbl);
            li.html(bg);
            ul.append(li).fadeIn(500);
        }

        return ul;
    }

    return {
        initialize: initializeEtsTree,
        loadConceptNodes: loadConceptNodes,
        TreeDirection: TreeDirection
    };
})();
*/
