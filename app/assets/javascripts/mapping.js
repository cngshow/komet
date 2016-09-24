var MappingModule = (function () {

    const SET_LIST = 'set_list';
    const SET_DETAILS = 'set_details';
    const SET_EDITOR = 'set_editor';
    const ITEM_EDITOR = 'item_editor';
    const CREATE_SET = 'create_set';

    function init() {

        subscribeToMappingTree();

        var windowType;

        /*if (WindowManager.viewers.inlineViewers.length == 0){
            windowType = WindowManager.NEW;
        }*/

        this.tree = new KometMappingTree("komet_mapping_tree", null);

        /*
        showOverviewSTAMP = false;
        showOverviewInactiveConcepts = false;

        loadOverviewSetsGrid();

        */

    }

    function subscribeToMappingTree() {

        // listen for the onChange event broadcast by any of the taxonomy this.trees.
        $.subscribe(KometChannels.Mapping.mappingTreeNodeSelectedChannel, function (e, treeID, setID, viewerID, windowType) {

            //viewerID = WindowManager.getLinkedViewerID();

            var action;

            if (setID == null || setID == 0){
                action = SET_LIST;
            } else {
                action = SET_DETAILS;
            }

            callLoadViewerData(setID, action, viewerID, windowType);
        });
    }

    function callLoadViewerData(setID, mappingAction, viewerID, windowType) {

        if (WindowManager.deferred && WindowManager.deferred.state() == "pending"){
            WindowManager.deferred.done(function(){
                loadViewerData(setID, mappingAction, WindowManager.getLinkedViewerID(), windowType)
            }.bind(this));
        } else {
            loadViewerData(setID, mappingAction, viewerID, windowType);
        }
    }

    // the path to a javascript partial file that will re-render all the appropriate partials once the ajax call returns
    function loadViewerData(setID, mappingAction, viewerID, windowType) {

        WindowManager.deferred = $.Deferred();

        var params = {partial: 'komet_dashboard/mapping/mapping_viewer', mapping_action: mappingAction, viewer_id: viewerID, set_id: setID};
        var url = gon.routes.mapping_load_mapping_viewer_path;

        if (mappingAction == CREATE_SET && WindowManager.viewers.inlineViewers.length > 0 && WindowManager.viewers[viewerID].currentSetID != 0 && (windowType == null || windowType == WindowManager.INLINE)){
            params.previous_set_id = WindowManager.viewers[viewerID].currentSetID;
        }

        if (WindowManager.viewers.inlineViewers.length == 0 || WindowManager.getLinkedViewerID() == WindowManager.NEW){
            windowType = WindowManager.NEW;
        }

        // make an ajax call to get the concept for the current concept and pass it the currently selected concept id and the name of a partial file to render
        $.get(url, params, function (data) {

            try {

                WindowManager.loadViewerData(data, viewerID, "mapping", windowType);

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

    function createViewer(viewerID, setID, mappingAction) {

        WindowManager.createViewer(new MappingViewer(viewerID, setID, mappingAction));

        // resolve waiting requests now that processing is done.
        WindowManager.deferred.resolve();
    }

    function openSetEditor(newSet) {

        var url = gon.routes.mapping_map_set_editor_path;

        if (!newSet) {
            url += "?set_id=" + overviewSetsGridOptions.api.getSelectedRows()[0].id;
        }

        setEditorWindow = window.open(url, "MapSetEditor", "width=600,height=330");
    }

    function createNewMapSet(selectMappingTab) {

        if (selectMappingTab) {
            $("#komet_dashboard_tabs").tabs({active:1});
        }

        callLoadViewerData(null, MappingModule.CREATE_SET, WindowManager.getLinkedViewerID());
    }

    return {
        initialize: init,
        callLoadViewerData: callLoadViewerData,
        createViewer: createViewer,
        openSetEditor: openSetEditor,
        createNewMapSet: createNewMapSet,
        SET_LIST: SET_LIST,
        SET_DETAILS: SET_DETAILS,
        SET_EDITOR: SET_EDITOR,
        ITEM_EDITOR: ITEM_EDITOR,
        CREATE_SET: CREATE_SET
    };

})();