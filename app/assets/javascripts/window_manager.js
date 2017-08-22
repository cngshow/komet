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
    var deferred = null;


    function loadViewerData(viewerContent, viewerID, viewerType, windowType) {

        if (windowType == NEW && viewers.inlineViewerCount === viewers.maxInlineViewers){
            alert("You can not have more than two viewers open in the dashboard at one time.");
            return;
        }

        UIHelper.clearAutoSuggestRecentCache();

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

            nestedSplittersExist();

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

        if (viewerExists) {

            viewer.viewer_previous_content_id = viewers[viewer.viewerID].viewer_previous_content_id;
            viewer.viewer_previous_content_type = viewers[viewer.viewerID].viewer_previous_content_type;
        }

        viewers[viewer.viewerID] = viewer;

        // if the new viewer is not a popup
        if ($("#komet_viewer_" + viewer.viewerID).parents("#komet_east_pane").length > 0){

            if (!viewerExists) {
                viewers.inlineViewers.push(viewer.viewerID);
            }

            toggleViewerLinkage(viewer.viewerID, true);
        }
    }

    function registerPreviousViewerContent(viewerID) {

        console.log("*** registerPreviousViewerContent viewer ID: " + viewerID);
        console.log("*** registerPreviousViewerContent viewer action: " + WindowManager.viewers[viewerID].viewerAction);

        var viewer = WindowManager.viewers[viewerID];
        var viewerName = "ConceptViewer";

        // if the viewer doesn't have an initConcept method then it's a MappingViewer object
        if (viewer.initConcept == undefined){
            viewerName = "MappingViewer";
        }

        if (viewerName == "ConceptViewer" && (viewer.viewerAction == ConceptsModule.VIEW || viewer.viewerAction == ConceptsModule.EDIT_VIEW)){

            viewer.viewer_previous_content_id = viewer.currentConceptID;

        } else if (viewerName == "MappingViewer" && (viewer.viewerAction == MappingModule.SET_LIST || viewer.viewerAction == MappingModule.SET_DETAILS)){

            viewer.viewer_previous_content_id = viewer.currentSetID;
        }

        viewer.viewer_previous_content_type = viewerName;

        console.log("*** registerPreviousViewerContent previous content type: " + viewer.viewer_previous_content_type);
        console.log("*** registerPreviousViewerContent previous content id: " + viewer.viewer_previous_content_id);
    }

    function cancelEditMode(viewerID) {

        var viewer = WindowManager.viewers[viewerID];

        console.log("*** cancelEditMode viewer ID: " + viewerID);
        console.log("*** cancelEditMode previous content type: " + viewer.viewer_previous_content_type);
        console.log("*** cancelEditMode previous content id: " + viewer.viewer_previous_content_id);

        $("#komet_viewer_" + viewerID).off('unsavedCheck');

        if (viewer.viewer_previous_content_type && viewer.viewer_previous_content_id){

            if (viewer.viewer_previous_content_type == "ConceptViewer"){
                console.log("*** cancelEditMode ConceptViewer");
                console.log("*** cancelEditMode ConceptViewer View Params: " + TaxonomyModule.getStatedView());

                $.publish(KometChannels.Taxonomy.taxonomyTreeNodeSelectedChannel, ["", viewer.viewer_previous_content_id, TaxonomyModule.getViewParams(), viewerID, WindowManager.INLINE]);
                return false;

            } else if (viewer.viewer_previous_content_type == "MappingViewer"){
                console.log("*** cancelEditMode MappingViewer");
                console.log("*** cancelEditMode MappingViewer View Params: " + MappingModule.getViewParams());

                $.publish(KometChannels.Mapping.mappingTreeNodeSelectedChannel, ["", viewer.viewer_previous_content_id, MappingModule.getViewParams(), viewerID, WindowManager.INLINE]);
                return false;
            }
        }

        WindowManager.closeViewer(viewerID.toString());
        return false;
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

        nestedSplittersExist();
    }

    function toggleViewerLinkage(viewerID, makeLinked) {

        var otherViewerID;

        if (makeLinked) {

            otherViewerID = linkedViewerID;

            if (otherViewerID != undefined && otherViewerID != NEW && otherViewerID != viewerID && viewers[otherViewerID] != undefined) {
                viewers[otherViewerID].swapLinkIcon(false);
            }

            setLinkedViewerID(viewerID);

        } else {

            if (viewers.inlineViewers.length > 1){

                otherViewerID = getUnlinkedViewerID();

                setLinkedViewerID(otherViewerID);
                viewers[otherViewerID].swapLinkIcon(true);

            } else {
                setLinkedViewerID(NEW, NEW);
            }
        }

        viewers[viewerID].swapLinkIcon(makeLinked);
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

    function getUnlinkedViewerID(){

        var otherViewerID = null;

        if (viewers.inlineViewers.length > 1) {

            function findOtherViewer(value) {
                return value != getLinkedViewerID();
            }

            var viewerIndex = viewers.inlineViewers.findIndex(findOtherViewer);
            otherViewerID = viewers.inlineViewers[viewerIndex];
        }

        return otherViewerID;
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
        callLoadViewerData: loadViewerData,
        registerPreviousViewerContent: registerPreviousViewerContent,
        cancelEditMode: cancelEditMode,
        closeViewer: closeViewer,
        toggleViewerLinkage: toggleViewerLinkage,
        setLinkedViewerID: setLinkedViewerID,
        getLinkedViewerID: getLinkedViewerID,
        getUnlinkedViewerID: getUnlinkedViewerID,
        nestedSplittersExist: nestedSplittersExist,
        refreshSplitters: refreshSplitters,
        deferred: deferred,
        INLINE: INLINE,
        NEW: NEW,
        POPUP: POPUP,
        viewers: viewers
    };

})();
