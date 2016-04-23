var TaxonomyModule = (function () {

    function init() {

        this.tree = new KometTaxonomyTree("taxonomy_tree", $("#komet_taxonomy_stated_inferred")[0].value, false, null, true);
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

    return {
        initialize: init
    };

})();
