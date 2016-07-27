var ConceptsModule = (function () {

    var panelStates = {};
    var viewers = {};
    viewers.inlineViewers = [];
    viewers.maxInlineViewers = 2;
    var viewerMode = "single";
    var loading = false;
    var deferred;

    function subscribeToTaxonomyTree() {

        // listen for the onChange event broadcast by any of the taxonomy this.trees.
        $.subscribe(KometChannels.Taxonomy.taxonomyTreeNodeSelectedChannel, function (e, treeID, conceptID, stated, viewerID, windowType) {

            if (deferred && deferred.state() == "pending"){
                deferred.done(function(){
                    ConceptsModule.loadViewerData(conceptID, stated, WindowManager.getLinkedViewerID(), windowType)
                }.bind(this));
            } else {
                ConceptsModule.loadViewerData(conceptID, stated, viewerID, windowType);
            }
        });
    }

    function subscribeToSearch() {

        // listen for the onChange event broadcast by selecting a search result.
        $.subscribe(KometChannels.Taxonomy.taxonomySearchResultSelectedChannel, function (e, conceptID, viewerID, windowType) {

            ConceptsModule.loadViewerData(conceptID, TaxonomyModule.defaultStatedView, viewerID, windowType);
        });
    }

    function loadViewerData(conceptID, stated, viewerID, windowType) {

        loading = true;
        deferred = $.Deferred();

        // the path to a javascript partial file that will re-render all the appropriate partials once the ajax call returns
        var partial = 'komet_dashboard/concept_detail/concept_information';

        // make an ajax call to get the concept for the current concept and pass it the currently selected concept id and the name of a partial file to render
        $.get(gon.routes.taxonomy_get_concept_information_path, {
            concept_id: conceptID,
            stated: stated,
            partial: partial,
            viewer_id: viewerID
        }, function (data) {

            try {

                WindowManager.loadViewerData(data, viewerID, "concept", windowType);

                if (windowType != WindowManager.NEW && windowType != WindowManager.POPUP) {

                    WindowManager.viewers[viewerID].refsetGridOptions = null;
                    deferred.resolve();
                }
            }
            catch (err) {
                console.log("*******  ERROR **********");
                console.log(err.message);
                throw err;
            }

        });
    }

    function createViewer(viewerID, conceptID) {

        WindowManager.createViewer(new ConceptViewer(viewerID, conceptID));
        deferred.resolve();
    }

    function setStatedView(viewerID, field) {
        loadViewerData(WindowManager.viewers[viewerID].currentConceptID, field.value, viewerID);
    }

    function init() {

        subscribeToTaxonomyTree();
        subscribeToSearch();
    }

    return {
        initialize: init,
        createViewer: createViewer,
        loadViewerData: loadViewerData,
        setStatedView: setStatedView,
        viewers: viewers
    };

})();
