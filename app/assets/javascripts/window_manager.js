var WindowManager = (function () {

    var viewers = {};
    viewers.inlineViewers = [];
    viewers.maxInlineViewers = 2;
    var linkedViewerID;
    var viewerMode = "single";
    const INLINE = "inline";
    const NEW = "new";
    const POPUP = "popup";

    function loadViewerData(viewerContent, viewerID, viewerType, windowType) {

        if (windowType == NEW && viewers.inlineViewerCount === viewers.maxInlineViewers){
            alert("You can not have more than two concept viewers open in the dashboard at one time.");
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

        viewers[viewer.viewerID] = viewer;

        if ($("#komet_viewer_" + viewer.viewerID).parents("#komet_east_pane").length > 0){

            viewers.inlineViewers.push(viewer.viewerID);
            //TaxonomyModule.setLinkedViewerID(viewerID);
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

        TaxonomyModule.tree.windowType = windowType;
        
        if (windowType != NEW && TaxonomyModule.tree.selectedConceptID != viewers[viewerID].currentConceptID) {
            viewers[viewerID].showInTaxonomyTree();
        }
    }

    function getLinkedViewerID(){
        return linkedViewerID;
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
        INLINE: INLINE,
        NEW: NEW,
        POPUP: POPUP,
        viewers: viewers
    };

})();
