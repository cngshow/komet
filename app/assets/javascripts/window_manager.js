var WindowManager = (function () {

    const INLINE = "inline";
    const NEW = "new";
    const POPUP = "popup";
    var viewers = {};
    viewers.inlineViewers = [];
    viewers.maxInlineViewers = 2;
    var linkedViewerID = NEW;
    var nestedSplitters;
    var hasNestedSplitters = false;
    var viewerMode = "single";


    function loadViewerData(viewerContent, viewerID, viewerType, windowType) {

        if (windowType == NEW && viewers.inlineViewerCount === viewers.maxInlineViewers){
            alert("You can not have more than two viewers open in the dashboard at one time.");
            return;
        }

        var range = document.createRange();

        if (windowType == NEW) {

            if ((viewers.inlineViewers.length + 1) % 2) {

                var splitter = '<div id="komet_east_pane_splitter_1" class="komet-splitter"><div>' + viewerContent + '</div></div>';
                var documentFragment = range.createContextualFragment(splitter);
                $('#komet_east_pane').append(documentFragment);

            } else {

                var splitter = $("#komet_east_pane_splitter_1");

                var documentFragment = range.createContextualFragment("<div>" + viewerContent + "</div>");
                splitter.append(documentFragment);
                splitter.enhsplitter({height: "100%", width: "100%"});
            }

        } else if (windowType == POPUP){

            var newWindow = window.open("#");
            newWindow.html(viewerContent);

        } else {

            var viewerElement = $('#komet_viewer_' + viewerID);
            var documentFragment = range.createContextualFragment(viewerContent);

            viewerElement.scrollParent()[0].scrollTop = 0;
            viewerElement[0].parentNode.replaceChild(documentFragment, viewerElement[0]);
        }
}

    function createViewer(viewer) {

        var viewerExists = WindowManager.viewers.hasOwnProperty(viewer.viewerID);

        viewers[viewer.viewerID] = viewer;

        // if the new viewer is not a popup
        if ($("#komet_viewer_" + viewer.viewerID).parents("#komet_east_pane").length > 0){

            if (!viewerExists) {
                viewers.inlineViewers.push(viewer.viewerID);
            }

            toggleViewerLinkage(viewer.viewerID, true);
        }
    }

    function closeViewer(viewerID) {

        var splitter = $("#komet_east_pane_splitter_1");

        if (!(viewers.inlineViewers.length % 2)) {
            splitter.enhsplitter('remove');
        }

        $('#komet_viewer_' + viewerID).parent().remove();
        delete viewers[viewerID];

        viewers.inlineViewers.splice(viewers.inlineViewers.indexOf(viewerID), 1);

        var otherViewer;

        if (viewers.inlineViewers.length === 1) {

            otherViewer = $("div[id^=komet_viewer_]");
            otherViewer.parent().attr("style", "");
        }

        if (linkedViewerID == viewerID) {

            if (viewers.inlineViewers.length === 1) {
                toggleViewerLinkage(otherViewer.attr("data-komet-viewer-id"), true);
            } else {

                setLinkedViewerID(NEW, NEW);
                splitter.remove();
            }
        }
    }

    function toggleViewerLinkage(viewerID, makeActive) {

        var otherViewerID;

        if (makeActive) {

            otherViewerID = linkedViewerID;

            if (otherViewerID != undefined && otherViewerID != NEW && otherViewerID != viewerID && viewers[otherViewerID] != undefined) {
                viewers[otherViewerID].swapLinkIcon(false);
            }

            setLinkedViewerID(viewerID);

        } else {

            if (viewers.inlineViewers.length > 1){

                var viewerIndex = viewers.inlineViewers.findIndex(findOtherViewer);
                otherViewerID = viewers.inlineViewers[viewerIndex];

                function findOtherViewer(value){
                    return value != viewerID;
                }

                setLinkedViewerID(otherViewerID);
                viewers[otherViewerID].swapLinkIcon(true);

            } else {
                setLinkedViewerID(NEW, NEW);
            }
        }

        viewers[viewerID].swapLinkIcon(makeActive);
    }

    function setLinkedViewerID(viewerID, windowType){

        linkedViewerID = viewerID;

        if (viewers[viewerID] instanceof ConceptViewer && windowType != NEW && TaxonomyModule.tree.selectedConceptID != viewers[viewerID].currentConceptID) {
            //TaxonomyModule.tree.windowType = windowType;
            viewers[viewerID].showInTaxonomyTree();


        } else if (viewers[viewerID] instanceof MappingViewer && windowType != NEW && MappingModule.tree.selectedSetID != viewers[viewerID].currentSetID) {
            viewers[viewerID].showInMappingTree();
        }
    }

    function getLinkedViewerID(){
        return linkedViewerID;
    }

    function nestedSplittersExist(){

        nestedSplitters = $("#komet_east_pane_splitter_1");
        hasNestedSplitters = nestedSplitters.find(".splitter_bar").length > 0;
    }

    function refreshSplitters(){

        if (hasNestedSplitters){
            nestedSplitters.enhsplitter('refresh');
        }
    }

    function init() {

    }

    return {
        initialize: init,
        createViewer: createViewer,
        loadViewerData: loadViewerData,
        closeViewer: closeViewer,
        toggleViewerLinkage: toggleViewerLinkage,
        setLinkedViewerID: setLinkedViewerID,
        getLinkedViewerID: getLinkedViewerID,
        nestedSplittersExist: nestedSplittersExist,
        refreshSplitters: refreshSplitters,
        INLINE: INLINE,
        NEW: NEW,
        POPUP: POPUP,
        viewers: viewers
    };

})();
