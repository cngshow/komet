var ConceptsModule = (function () {

    const VIEW = 'view_concept';
    const CREATE = 'create_concept';
    const EDIT = 'edit_concept';

    function init() {

        // listen for the onChange event broadcast by any of the taxonomy trees.
        $.subscribe(KometChannels.Taxonomy.taxonomyTreeNodeSelectedChannel, function (e, treeID, conceptID, stated, viewerID, windowType) {

            callLoadViewerData(conceptID, stated, VIEW, viewerID, windowType);
        });

        // listen for the onChange event broadcast by selecting a search result.
        $.subscribe(KometChannels.Taxonomy.taxonomySearchResultSelectedChannel, function (e, conceptID, viewerID, windowType) {

            callLoadViewerData(conceptID, TaxonomyModule.defaultStatedView, VIEW, viewerID, windowType);
        });

        // listen for the onChange event broadcast for creating or editing a concept.
        $.subscribe(KometChannels.Taxonomy.taxonomyConceptEditorChannel, function (e, conceptID, viewerID, windowType, params) {

            var viewerAction = EDIT;

            if (conceptID === null || conceptID === ""){
                viewerAction = CREATE;
            }

            callLoadViewerData(conceptID, TaxonomyModule.defaultStatedView, viewerAction, viewerID, windowType, params);
        });
    }

    function callLoadViewerData(conceptID, stated, viewerAction, viewerID, windowType, params) {

        if (WindowManager.deferred && WindowManager.deferred.state() == "pending"){

            WindowManager.deferred.done(function(){
                loadViewerData(conceptID, stated, viewerAction, WindowManager.getLinkedViewerID(), windowType, params)
            }.bind(this));

        } else {
            loadViewerData(conceptID, stated, viewerAction, viewerID, windowType, params);
        }
    }

    function loadViewerData(conceptID, stated, viewerAction, viewerID, windowType, params) {

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
        var restParameters = {concept_id: conceptID, stated: stated, partial: partial, viewer_id: viewerID, viewer_action: viewerAction};
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
        else if (viewerAction == EDIT) {

            restPath = gon.routes.taxonomy_get_concept_edit_info_path;
            restParameters.partial = 'komet_dashboard/concept_detail/concept_edit';
        }

        if ((viewerAction == EDIT || viewerAction == CREATE) && WindowManager.viewers.inlineViewers.length > 0  && (windowType == null || windowType == WindowManager.INLINE)){

            if (WindowManager.viewers[viewerID].constructor.name = "ConceptViewer" && WindowManager.viewers[viewerID].viewerAction == VIEW){

                restParameters.viewer_previous_content_id = WindowManager.viewers[viewerID].currentConceptID;

            } else if (WindowManager.viewers[viewerID].constructor.name = "MappingViewer" && (WindowManager.viewers[viewerID].viewerAction == MappingModule.SET_LIST || WindowManager.viewers[viewerID].viewerAction == MappingModule.SET_DETAILS)){

                restParameters.viewer_previous_content_id = WindowManager.viewers[viewerID].currentSetID;
            }

            restParameters.viewer_previous_content_type = WindowManager.viewers[viewerID].constructor.name

        }

        // make an ajax call to get the concept for the current concept and pass it the currently selected concept id and the name of a partial file to render
        $.get(restPath, restParameters, function (data) {

            try {

                WindowManager.loadViewerData(data, viewerID, "concept", windowType);

                onSuccess();

                // only resolve waiting requests if this is an inline viewer. New and popup viewers still have more processing.
                if (windowType != WindowManager.NEW && windowType != WindowManager.POPUP) {
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

    function createViewer(viewerID, conceptID, viewerAction) {

        WindowManager.createViewer(new ConceptViewer(viewerID, conceptID, viewerAction));

        // resolve waiting requests now that processing is done.
        WindowManager.deferred.resolve();
    }

    function setStatedView(viewerID, field) {
        loadViewerData(WindowManager.viewers[viewerID].currentConceptID, field.value, VIEW, viewerID);
    }

    return {
        initialize: init,
        createViewer: createViewer,
        loadViewerData: loadViewerData,
        setStatedView: setStatedView,
        VIEW: VIEW,
        EDIT: EDIT,
        CREATE: CREATE
    };

})();
