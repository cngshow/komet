var Taxonomy = {
    onReady: function(jstree_id, rest_paths) {
        var settings = {
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
        };

        $(jstree_id).jstree(settings);
        $(jstree_id).on('after_open.jstree', Taxonomy.onAfterOpen);

        Taxonomy.tree = $(jstree_id).jstree();
    },
    onAfterOpen: function(node) {
        console.log("******** after open on " + node);
    }
};



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
