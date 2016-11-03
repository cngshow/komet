var MappingModule = (function () {

    const SET_LIST = 'set_list';
    const SET_DETAILS = 'set_details';
    const SET_EDITOR = 'edit_set';
    const ITEM_EDITOR = 'item_editor';
    const CREATE_SET = 'create_set';

    function init() {

        // listen for the onChange event broadcast by any of the taxonomy this.trees.
        $.subscribe(KometChannels.Mapping.mappingTreeNodeSelectedChannel, function (e, treeID, setID, viewParams, viewerID, windowType, action) {

            if (action == undefined || action == null) {

                if (setID == null || setID == 0) {
                    action = SET_LIST;
                } else {
                    action = SET_DETAILS;
                }
            }

            callLoadViewerData(setID, viewParams, action, viewerID, windowType);
        });

        this.tree = new KometMappingTree("komet_mapping_tree", getTreeViewParams(), null);
    }

    function callLoadViewerData(setID, viewParams, viewerAction, viewerID, windowType) {

        if (WindowManager.deferred && WindowManager.deferred.state() == "pending"){
            WindowManager.deferred.done(function(){
                loadViewerData(setID, viewParams, viewerAction, WindowManager.getLinkedViewerID(), windowType)
            }.bind(this));
        } else {
            loadViewerData(setID, viewParams, viewerAction, viewerID, windowType);
        }
    }

    // the path to a javascript partial file that will re-render all the appropriate partials once the ajax call returns
    function loadViewerData(setID, viewParams, viewerAction, viewerID, windowType) {

        WindowManager.deferred = $.Deferred();

        var params = {partial: 'komet_dashboard/mapping/mapping_viewer', mapping_action: viewerAction, viewer_id: viewerID, set_id: setID, view_params: viewParams};
        var url = gon.routes.mapping_load_mapping_viewer_path;

        if (viewerAction == CREATE_SET && WindowManager.viewers.inlineViewers.length > 0 && WindowManager.viewers[viewerID].currentSetID != 0 && (windowType == null || windowType == WindowManager.INLINE)){
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

    function createViewer(viewerID, setID, viewerAction) {

        WindowManager.createViewer(new MappingViewer(viewerID, setID, viewerAction));

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

        $.publish(KometChannels.Mapping.mappingTreeNodeSelectedChannel, ["", null, MappingModule.getTreeViewParams(), WindowManager.getLinkedViewerID(), WindowManager.INLINE, MappingModule.CREATE_SET]);
    }

    function setViewerStatesToView(viewerID, field) {

        var viewParams = WindowManager.viewers[viewerID].getViewParams();
        viewParams.statesToView = field.value;
        $.publish(KometChannels.Mapping.mappingTreeNodeSelectedChannel, ["", WindowManager.viewers[viewerID].currentSetID, viewParams, viewerID, WindowManager.INLINE, WindowManager.viewers[viewerID].mapping_action]);
    }

    function setTreeStatesToView(field) {

        var viewParams = getTreeViewParams();
        viewParams.statesToView = field.value;
        this.tree.reloadTreeStatedView(viewParams);
    }

    function getTreeStatesToView (){
        return $("#komet_mapping_tree_panel").find("input[name='komet_mapping_tree_states_to_view']:checked").val();
    }

    function getTreeViewParams (){
        return {statesToView: getTreeStatesToView()};
    }

    return {
        initialize: init,
        callLoadViewerData: callLoadViewerData,
        createViewer: createViewer,
        openSetEditor: openSetEditor,
        createNewMapSet: createNewMapSet,
        setViewerStatesToView: setViewerStatesToView,
        setTreeStatesToView: setTreeStatesToView,
        getTreeStatesToView: getTreeStatesToView,
        getTreeViewParams: getTreeViewParams,
        SET_LIST: SET_LIST,
        SET_DETAILS: SET_DETAILS,
        SET_EDITOR: SET_EDITOR,
        ITEM_EDITOR: ITEM_EDITOR,
        CREATE_SET: CREATE_SET
    };

})();