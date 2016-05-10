var ConceptsModule = (function () {

    var panelStates = {};
    var viewers = {};
    viewers.inlineViewerCount = 0;
    viewers.maxInlineViewers = 2;
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

        // viewerID = "new";
        var newViewer = false;

        if (viewerID === "new" || viewerID === "popup"){

            if (viewerID === "new" && viewers.inlineViewerCount === viewers.maxInlineViewers){
                alert("You can not have more than two concept viewers open in the dashboard at one time.");
                return;
            }

            newViewer = viewerID;
            viewerID = null;
        }

        // make an ajax call to get the concept for the current concept and pass it the currently selected concept id and the name of a partial file to render
        $.get(gon.routes.taxonomy_get_concept_information_path, {
            concept_id: conceptID,
            stated: stated,
            partial: partial,
            viewer_id: viewerID
        }, function (data) {

            try {

                var range = document.createRange();

                if (newViewer === "new") {

                    viewers.inlineViewerCount += 1;

                    if (viewers.inlineViewerCount % 2) {

                        var splitter = '<div id="komet_east_pane_splitter_' + viewers.inlineViewerCount + '" class="komet-splitter"><div>' + data + '</div></div>';
                        var documentFragment = range.createContextualFragment(splitter);
                        $('#komet_east_pane').append(documentFragment);


                    } else {

                        var splitter = $("#komet_east_pane_splitter_" + (viewers.inlineViewerCount - 1));

                        var documentFragment = range.createContextualFragment("<div>" + data + "</div>");
                        splitter.append(documentFragment);
                        splitter.split({orientation: 'vertical', position: '50%', limit: 50});
                    }

                } else if (newViewer === "popup"){

                    var newWindow = window.open("#");
                    newWindow.html(data);

                } else {

                    var viewerElement = $('#komet_concept_panel_' + viewerID);
                    viewers[viewerID].refsetGridOptions = null;

                    var documentFragment = range.createContextualFragment(data);

                    viewerElement[0].parentNode.scrollTop = 0;
                    viewerElement[0].parentNode.replaceChild(documentFragment, viewerElement[0]);
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

        viewers[viewerID] = new ConceptViewer(viewerID, conceptID);

        if (viewerMode === "single") {
            TaxonomyModule.setLinkedViewerID(viewerID);
        }
    }

    function closeViewer(viewerID) {

        if (!(viewers.inlineViewerCount % 2)) {
            $("#komet_east_pane_splitter_" + (viewers.inlineViewerCount - 1)).split().destroy();
        }

        $('#komet_concept_panel_' + viewerID).parent().remove();
        delete viewers[viewerID];
        viewers.inlineViewerCount -= 1;

        var otherViewer;

        if (viewers.inlineViewerCount === 1) {

            otherViewer = $("div[id^=komet_concept_panel_]");
            otherViewer.parent().attr("style", "");
        }

        if (TaxonomyModule.getLinkedViewerID() == viewerID) {

            if (viewers.inlineViewerCount === 1) {
                TaxonomyModule.setLinkedViewerID(otherViewer.attr("data-komet-viewer-id"));
            } else {
                TaxonomyModule.setLinkedViewerID("new");
            }
        }
    }

    function setStatedView(viewerID, field) {
        loadViewerData(viewers[viewerID].currentConceptID, field.value, viewerID);
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
        closeViewer: closeViewer,
        viewers: viewers
    };

})();
