var ConceptsModule = (function () {

    const VIEW = 'view_concept';
    const CREATE = 'create_concept';
    const EDIT = 'edit_concept';
    const CLONE = 'clone_concept';

    function init() {

        // listen for the onChange event broadcast by any of the taxonomy trees.
        $.subscribe(KometChannels.Taxonomy.taxonomyTreeNodeSelectedChannel, function (e, treeID, conceptID, viewParams, viewerID, windowType) {
            callLoadViewerData(conceptID, viewParams, VIEW, viewerID, windowType);
        });

        // listen for the onChange event broadcast by selecting a search result.
        $.subscribe(KometChannels.Taxonomy.taxonomySearchResultSelectedChannel, function (e, conceptID, viewParams, viewerID, windowType) {
            callLoadViewerData(conceptID, viewParams, VIEW, viewerID, windowType);
        });

        // listen for the onChange event broadcast for creating or editing a concept.
        $.subscribe(KometChannels.Taxonomy.taxonomyConceptEditorChannel, function (e, viewerAction, conceptID, viewParams, viewerID, windowType, params) {
            callLoadViewerData(conceptID, viewParams, viewerAction, viewerID, windowType, params);
        });
    }

    function callLoadViewerData(conceptID, viewParams, viewerAction, viewerID, windowType, params) {

        if (WindowManager.deferred && WindowManager.deferred.state() == "pending"){

            WindowManager.deferred.done(function(){
                loadViewerData(conceptID, viewParams, viewerAction, WindowManager.getLinkedViewerID(), windowType, params)
            }.bind(this));

        } else {
            loadViewerData(conceptID, viewParams, viewerAction, viewerID, windowType, params);
        }
    }

    function loadViewerData(conceptID, viewParams, viewerAction, viewerID, windowType, params) {

        var isDirty = $('#komet_viewer_' + viewerID).triggerHandler("unsavedCheck");

        if (isDirty){
            return false;
        }

        Common.cursor_wait();
        WindowManager.deferred = $.Deferred();

        if (WindowManager.viewers.inlineViewers.length == 0 || WindowManager.getLinkedViewerID() == WindowManager.NEW){
            windowType = WindowManager.NEW;
        }

        if (viewerAction == undefined || viewerAction == null){
            viewerAction = VIEW;
        }

        // the path to a javascript partial file that will re-render all the appropriate partials once the ajax call returns
        var restPath = gon.routes.taxonomy_get_concept_information_path;
        var partial = "komet_dashboard/concept_detail/concept_information";
        var restParameters = {concept_id: conceptID, view_params: viewParams, partial: partial, viewer_id: viewerID, viewer_action: viewerAction};
        var onSuccess = function() {};

        if (viewerAction == VIEW) {

            onSuccess = function() {

                if (windowType != WindowManager.NEW && windowType != WindowManager.POPUP) {

                    WindowManager.viewers[viewerID].refsetGridOptions = null;
                }
            };
        }
        else if (viewerAction == CREATE) {

            restPath = gon.routes.taxonomy_get_concept_create_info_path;
            restParameters.partial = 'komet_dashboard/concept_detail/concept_add';

            if (params !== undefined && params !== null){

                restParameters.parent_id = params.parentID;
                restParameters.parent_text = params.parentText;
                restParameters.parent_type = params.parentType;
            }
        }
        else if (viewerAction == EDIT || viewerAction == CLONE) {

            restPath = gon.routes.taxonomy_get_concept_edit_info_path;
            restParameters.partial = 'komet_dashboard/concept_detail/concept_edit';
        }

        if ((viewerAction == EDIT || viewerAction == CREATE || viewerAction == CLONE) && WindowManager.viewers.inlineViewers.length > 0  && (windowType == null || windowType == WindowManager.INLINE)){
            WindowManager.registerPreviousViewerContent(viewerID);
        }

        // make an ajax call to get the concept for the current concept and pass it the currently selected concept id and the name of a partial file to render
        $.get(restPath, restParameters, function (data) {

            try {

                onSuccess();

                WindowManager.callLoadViewerData(data, viewerID, "concept", windowType);

                // only resolve waiting requests if this is an inline viewer. New and popup viewers still have more processing.
                if (windowType != WindowManager.NEW && windowType != WindowManager.POPUP) {
                    WindowManager.deferred.resolve();
                }

                Common.cursor_auto();
            }
            catch (err) {

                console.log("*******  ERROR **********");
                console.log(err.message);
                Common.cursor_auto();
                throw err;
            }
        });
    }

    function createViewer(viewerID, conceptID, viewerAction) {

        WindowManager.createViewer(new ConceptViewer(viewerID, conceptID, viewerAction));

        // resolve waiting requests now that processing is done.
        WindowManager.deferred.resolve();
    }

    return {
        initialize: init,
        createViewer: createViewer,
        callLoadViewerData: callLoadViewerData,
        VIEW: VIEW,
        EDIT: EDIT,
        CREATE: CREATE,
        CLONE: CLONE
    };

})();
