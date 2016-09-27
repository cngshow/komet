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

            var action = EDIT;

            if (conceptID === null || conceptID === ""){
                action = CREATE;
            }

            callLoadViewerData(conceptID, TaxonomyModule.defaultStatedView, action, viewerID, windowType, params);
        });
    }

    function callLoadViewerData(conceptID, stated, action, viewerID, windowType, params) {

        if (WindowManager.deferred && WindowManager.deferred.state() == "pending"){

            WindowManager.deferred.done(function(){
                loadViewerData(conceptID, stated, action, WindowManager.getLinkedViewerID(), windowType, params)
            }.bind(this));

        } else {
            loadViewerData(conceptID, stated, action, viewerID, windowType, params);
        }
    }

    function loadViewerData(conceptID, stated, action, viewerID, windowType, params) {

        WindowManager.deferred = $.Deferred();

        if (WindowManager.viewers.inlineViewers.length == 0 || WindowManager.getLinkedViewerID() == WindowManager.NEW){
            windowType = WindowManager.NEW;
        }

        if (action == undefined || action == null){
            action = VIEW;
        }

        // the path to a javascript partial file that will re-render all the appropriate partials once the ajax call returns
        var restPath = gon.routes.taxonomy_get_concept_information_path;
        var partial = "komet_dashboard/concept_detail/concept_information";
        var restParameters = {concept_id: conceptID, stated: stated, partial: partial, viewer_id: viewerID};
        var onSuccess = function() {};

        if (action == VIEW) {

            onSuccess = function() {

                if (windowType != WindowManager.NEW && windowType != WindowManager.POPUP) {

                    WindowManager.viewers[viewerID].refsetGridOptions = null;
                }
            };
        }
        else if (action == CREATE) {

            restPath = gon.routes.taxonomy_get_concept_create_info_path;
            restParameters.partial = 'komet_dashboard/concept_detail/concept_add';

            if (params !== undefined && params !== null){

                restParameters.parent_id = params.parentID;
                restParameters.parent_text = params.parentText;
                restParameters.parent_type = params.parentType;
            }
        }
        else if (action == EDIT) {

            restPath = gon.routes.taxonomy_get_concept_edit_info_path;
            restParameters.partial = 'komet_dashboard/concept_detail/concept_edit';
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

    function createViewer(viewerID, conceptID) {

        WindowManager.createViewer(new ConceptViewer(viewerID, conceptID));

        // resolve waiting requests now that processing is done.
        WindowManager.deferred.resolve();
    }

    function setStatedView(viewerID, field) {
        loadViewerData(WindowManager.viewers[viewerID].currentConceptID, field.value, viewerID);
    }

    return {
        initialize: init,
        createViewer: createViewer,
        loadViewerData: loadViewerData,
        setStatedView: setStatedView
    };

})();
