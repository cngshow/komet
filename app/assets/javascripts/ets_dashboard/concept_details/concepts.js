var ConceptsModule = (function () {

    function subscribeToTaxonomyTree() {
        $.subscribe(EtsChannels.Taxonomy.taxonomyTreeNodeClosedChannel, function(e, conceptID){
            //We received our event.  Due to the fine grained structure of our Observer/Observable paradigm
            //We need no if/else logic.  If this function receives an event it can just act on it.
            $('#jstree_observer').html("<h3>" + conceptID + " has been closed!</h3>");
        });
        $.subscribe(EtsChannels.Taxonomy.taxonomyTreeNodeOpenedChannel, function(e, conceptID) {
            $('#jstree_observer').html("<h3>" + conceptID + " has been opened!</h3>");
        });
    }

    function init() {
        subscribeToTaxonomyTree();
    }

    return {
        initialize : init
    };

})();
