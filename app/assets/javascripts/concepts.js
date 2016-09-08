var ConceptsModule = (function () {

    var panelStates = {};
    var viewers = {};
    viewers.inlineViewers = [];
    viewers.maxInlineViewers = 2;
    var viewerMode = "single";
    var loading = false;

    function subscribeToTaxonomyTree() {

        // listen for the onChange event broadcast by any of the taxonomy this.trees.
        $.subscribe(KometChannels.Taxonomy.taxonomyTreeNodeSelectedChannel, function (e, treeID, conceptID, stated, viewerID, windowType) {

            if (WindowManager.deferred && WindowManager.deferred.state() == "pending"){
                WindowManager.deferred.done(function(){
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

            ConceptsModule.loadViewerData(e,conceptID, viewerID, windowType);
        });
    }

    function loadViewerData(conceptID, stated, viewerID, windowType) {

        loading = true;
        WindowManager.deferred = $.Deferred();

        if (WindowManager.viewers.inlineViewers.length == 0 || WindowManager.getLinkedViewerID() == WindowManager.NEW){
            windowType = WindowManager.NEW;
        }

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
                    WindowManager.deferred.resolve();
                }
            }
            catch (err) {
                console.log("*******  ERROR **********");
                console.log(err.message);
                throw err;
            }

        });
    }
    function subscribeToAddConcept()
    {
        // listen for the onChange event broadcast by selecting a search result.
        $.subscribe(KometChannels.Taxonomy.taxonomyAddConceptChannel, function (e,conceptID, viewerID, windowType) {

            ConceptsModule.loadConceptPanel(conceptID,TaxonomyModule.defaultStatedView, viewerID, windowType,'AddConcept');
        });
    }

    function subscribeToEditConcept()
    {
        // listen for the onChange event broadcast by selecting a search result.
        $.subscribe(KometChannels.Taxonomy.taxonomyEditConceptChannel, function (e,conceptID, viewerID, windowType,divname) {

            ConceptsModule.loadConceptPanel(conceptID,TaxonomyModule.defaultStatedView, viewerID, windowType,'EditConcept',divname);
        });
    }

    function loadConceptPanel(conceptID, stated, viewerID, windowType,action,divname) {

        loading = true;
        deferred = $.Deferred();
      var selectedDivname = windowType;
        // the path to a javascript partial file that will re-render all the appropriate partials once the ajax call returns
     if (action == 'AddConcept') {
         windowType = WindowManager.New;
         var partial = 'komet_dashboard/concept_add';
         // make an ajax call to get the concept for the current concept and pass it the currently selected concept id and the name of a partial file to render
         $.get(gon.routes.taxonomy_get_concept_add_path, {
             concept_id: conceptID,
             stated: stated,
             partial: partial,
             viewer_id: viewerID,
             divname:divname
         }, function (data) {

             try {

                 WindowManager.loadViewerData(data, viewerID, "concept", windowType);

                 deferred.resolve();

             }
             catch (err) {
                 console.log("*******  ERROR **********");
                 console.log(err.message);
                 throw err;
             }

         });
     }
        else
     {
         windowType = WindowManager.INLINE;
         var partial = 'komet_dashboard/concept_edit';
         // make an ajax call to get the concept for the current concept and pass it the currently selected concept id and the name of a partial file to render
         $.get(gon.routes.taxonomy_get_concept_edit_path, {
             concept_id: conceptID,
             stated: stated,
             partial: partial,
             viewer_id: viewerID
         }, function (data) {

             try {

                 WindowManager.loadViewerData(data, viewerID, "concept", windowType);
                 $("#selectdivname").val(selectedDivname);
                 deferred.resolve();

             }
             catch (err) {
                 console.log("*******  ERROR **********");
                 console.log(err.message);
                 throw err;
             }

         });

     }
    }
    function createViewer(viewerID, conceptID) {

        WindowManager.createViewer(new ConceptViewer(viewerID, conceptID));
        WindowManager.deferred.resolve();
    }

    function setStatedView(viewerID, field) {
        loadViewerData(WindowManager.viewers[viewerID].currentConceptID, field.value, viewerID);
    }

    function init() {

        subscribeToTaxonomyTree();
        subscribeToSearch();
        subscribeToAddConcept();
        subscribeToEditConcept();
    }


    return {
        initialize: init,
        createViewer: createViewer,
        loadViewerData: loadViewerData,
        setStatedView: setStatedView,
        viewers: viewers,
        loadConceptPanel:loadConceptPanel
    };

})();
