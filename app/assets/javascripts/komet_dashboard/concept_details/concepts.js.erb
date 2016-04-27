var ConceptsModule = (function () {

  var panelStates = {};
  var viewers = {};
  var viewerMode = "single";

  function subscribeToTaxonomyTree() {

    // listen for the onChange event broadcast by any of the taxonomy this.trees.
    $.subscribe(KometChannels.Taxonomy.taxonomyTreeNodeSelectedChannel, function (e, treeID, conceptID, stated, viewerID) {

      //this.currentConceptID = conceptID;
      ConceptsModule.loadViewerData(conceptID, stated, viewerID);
    });
  }

  function subscribeToSearch() {

    // listen for the onChange event broadcast by selecting a search result.
    $.subscribe(KometChannels.Taxonomy.taxonomySearchResultSelectedChannel, function (e, conceptID, viewerID) {

      ConceptsModule.loadViewerData(conceptID, TaxonomyModule.defaultStatedView, viewerID);
    });
  }

  function loadViewerData(conceptID, stated, viewerID) {

    // the path to a javascript partial file that will re-render all the appropriate partials once the ajax call returns
    var partial = 'komet_dashboard/concept_detail/concept_information';

    // make an ajax call to get the concept for the current concept and pass it the currently selected concept id and the name of a partial file to render
    $.get(gon.routes.taxonomy_get_concept_information_path, {concept_id: conceptID, stated: stated, partial: partial, viewer_id: viewerID}, function (data) {

      try {
        $('#komet_east_pane').html(data);

      }
      catch (err) {
        console.log("*******  ERROR **********");
        console.log(err.message);
        throw err;
      }

    });
  }

  function createViewer(viewerID, conceptID) {

    viewers[viewerID] = new ConceptViewer(viewerID, conceptID);

    if (viewerMode === "single"){
      TaxonomyModule.setLinkedViewerID(viewerID);
    }
  }

  function setStatedView(viewerID, field){
    loadViewerData(viewers[viewerID].currentConceptID, field.value, viewerID);
  }

  function init(){

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
