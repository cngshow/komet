var TaxonomyModule = (function () {

    function buildTaxonomyTree(jstree_id) {
        var settings = {
            "core": {
                "animation": 0,
                "check_callback": true,
                "themes": {"stripes": true},
                'data': {
                    'url': gon.routes.taxonomy_load_data_path,
                    'data': function (node) {
                        return {'id': node.id};
                    }
                }
            }
        };
        $(jstree_id).jstree(settings);
        $(jstree_id).on('after_open.jstree', onAfterOpen);
        $(jstree_id).on('after_close.jstree', onAfterClose);
        $(jstree_id).on('changed.jstree', onChanged);
        TaxonomyModule.tree = $(jstree_id).jstree();
    }

    function onAfterOpen(node, selected) {
        //publish what we expect our observers to need in a way that allows them not to understand
        //our tree and our tree's dom.
        $.publish(EtsChannels.Taxonomy.taxonomyTreeNodeOpenedChannel,selected.node.id);

    }

    function onAfterClose(node, selected) {
        $.publish(EtsChannels.Taxonomy.taxonomyTreeNodeClosedChannel,selected.node.id);
    }

    function init(jstree_id) {
        buildTaxonomyTree(jstree_id);
    }

    function onChanged(event, selectedObject) {

        var conceptId = selectedObject.node.id;
        var parentConceptId = selectedObject.node.original.parent_id;
        console.log("Selected id : %s; Parent id: %s", conceptId, parentConceptId);

        var contentPane = $("#east-pane");
        contentPane.html("Viewing details for concept ID: " + conceptId + "; which has parent concept ID: " + parentConceptId);
    }

    return {
        initialize : init
    };

})();



/*
 var taxonomy = new function () {
 //public methods (defined as this. will be exposed in the taxonomy namespace)
 this.init = function (jstree_id, rest_paths) {
 $(jstree_id)
 .on('changed.jstree', function (e, data) {
 console.log("******** on changed of tree " + JSON.stringify(e));
 })
 .on('before_open.jstree', function (node) {
 console.log("******** before open on " + node);
 })
 .on('open_node.jstree', function (node) {
 console.log("******** open_node on" + node);
 })
 .on('after_open.jstree', function (node) {
 console.log("******** after open on " + node);
 })
 // create the instance
 .jstree({
 "core": {
 "animation": 0,
 "check_callback": true,
 "themes": {"stripes": true},
 'data': {
 'url': rest_paths.taxonomy_data_path,
 'data': function (node) {
 return {'id': node.id};
 }
 }
 }
 });
 };

 //private methods should be defined as var <function_name> = function(...)
 };

 */
