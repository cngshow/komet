var TaxonomyModule = (function () {

    var linkedViewerID;

    function init() {

        this.defaultStatedView = $("#komet_taxonomy_stated_inferred")[0].value;

        this.tree = new KometTaxonomyTree("taxonomy_tree", this.defaultStatedView, false, null, true);
    }

    // listen for the onChange event broadcast by the trees on the details panes. If they have items selected then reload this tree
    function subscribeToDetailsTaxonomyTrees() {

        $.subscribe(KometChannels.Taxonomy.taxonomyTreeRebaseChannel, function (e, treeID, conceptID) {
            this.tree.rebaseTreeAtConcept("taxonomy_tree", conceptID);
        });
    }

    // listen for the onChange event broadcast by the trees on the details panes. If they have items selected then reload this tree
    function onDoubleClick(event) {
        reloadTree(TaxonomyModule[event.currentTarget.id].selectedConceptID);
    }

    function setLinkedViewerID(viewerID){

        linkedViewerID = viewerID;
        this.tree.viewerID = viewerID;
    }

    function getLinkedViewerID(){
        return linkedViewerID;
    }

    return {
        initialize: init,
        setLinkedViewerID: setLinkedViewerID,
        getLinkedViewerID: getLinkedViewerID
    };

})();
