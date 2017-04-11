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

        this.tree = new KometMappingTree("komet_mapping_tree", getViewParams(), null);
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

        var isDirty = $('#komet_viewer_' + viewerID).triggerHandler("unsavedCheck");

        if (isDirty){
            return false;
        }

        Common.cursor_wait();
        WindowManager.deferred = $.Deferred();

        var params = {partial: 'komet_dashboard/mapping/mapping_viewer', mapping_action: viewerAction, viewer_id: viewerID, set_id: setID, view_params: viewParams};
        var url = gon.routes.mapping_load_mapping_viewer_path;

        if (viewerAction == CREATE_SET && WindowManager.viewers.inlineViewers.length > 0  && (windowType == null || windowType == WindowManager.INLINE)){
            WindowManager.registerPreviousViewerContent(viewerID);
        }

        if (WindowManager.viewers.inlineViewers.length == 0 || WindowManager.getLinkedViewerID() == WindowManager.NEW){
            windowType = WindowManager.NEW;
        }

        // make an ajax call to get the concept for the current concept and pass it the currently selected concept id and the name of a partial file to render
        $.get(url, params, function (data) {

            try {

                WindowManager.callLoadViewerData(data, viewerID, "mapping", windowType);

                // only resolve waiting requests if this is an inline viewer. New and popup viewers still have more processing.
                if (windowType != WindowManager.NEW && windowType != WindowManager.POPUP) {
                    WindowManager.deferred.resolve();
                }

                Common.cursor_auto();
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

        $.publish(KometChannels.Mapping.mappingTreeNodeSelectedChannel, ["", null, MappingModule.getViewParams(), WindowManager.getLinkedViewerID(), WindowManager.INLINE, MappingModule.CREATE_SET]);
    }

    //function setViewerStatesToView(viewerID) {
    //
    //    var viewParams = WindowManager.viewers[viewerID].getViewParams();
    //    $.publish(KometChannels.Mapping.mappingTreeNodeSelectedChannel, ["", WindowManager.viewers[viewerID].currentSetID, viewParams, viewerID, WindowManager.INLINE, WindowManager.viewers[viewerID].mapping_action]);
    //}

    function getStampDate() {

        var stamp_date = $("#komet_mapping_tree_stamp_date").find("input").val();

        if (stamp_date == '' || stamp_date == 'latest') {
            return 'latest';
        } else {
            return new Date(stamp_date).getTime().toString();
        }
    }

    function getAllowedStates(){
        return $("#komet_mapping_tree_allowed_states").val();
    }

    function getStampModules (){
        return $("#komet_mapping_tree_stamp_modules").val();
    }

    function getStampPath (){
        return $("#komet_mapping_tree_stamp_path").val();
    }

    // function to set the initial state of the view param fields when the viewer content changes
    function initViewParams(view_params) {

        // initialize the STAMP date field
        UIHelper.initDatePicker("#komet_mapping_tree_stamp_date", view_params.time);
    }

    function getViewParams (){
        return {time: getStampDate(), allowedStates: getAllowedStates(), modules: getStampModules(), path: getStampPath()};
    }

    // function to change the view param values and then reload the tree
    function setViewParams(view_params) {

        // set the STAMP date field
        UIHelper.setStampDate($("#komet_mapping_tree_stamp_date"), view_params.time);

        // set the Allowed States field
        $("#komet_mapping_tree_allowed_states").val(view_params.allowedStates);

        // set the modules field
        $("#komet_mapping_tree_stamp_modules").val(view_params.modules);

        // set the path field
        $("#komet_mapping_tree_stamp_path").val(view_params.path);

        // reload the tree
        this.reloadTree();
    }

    function reloadTree() {

        var selectedID = null;
        var linkedViewerID = WindowManager.getLinkedViewerID();

        // if there is a linked mapping viewer get its set ID to try to find the node and select it again after reload, without triggering the change event
        if (linkedViewerID != null && linkedViewerID != WindowManager.NEW && WindowManager.viewers[linkedViewerID].currentSetID){
            selectedID = WindowManager.viewers[linkedViewerID].currentSetID;
        }

        // reload the tree, trying to reselect a linked concept if there was one
        this.tree.reloadTree(getViewParams(), false, selectedID);
    }

    return {
        initialize: init,
        callLoadViewerData: callLoadViewerData,
        createViewer: createViewer,
        openSetEditor: openSetEditor,
        createNewMapSet: createNewMapSet,
        getStampDate: getStampDate,
        getAllowedStates: getAllowedStates,
        getStampModules: getStampModules,
        getStampPath: getStampPath,
        initViewParams: initViewParams,
        getViewParams: getViewParams,
        setViewParams: setViewParams,
        reloadTree: reloadTree,
        SET_LIST: SET_LIST,
        SET_DETAILS: SET_DETAILS,
        SET_EDITOR: SET_EDITOR,
        ITEM_EDITOR: ITEM_EDITOR,
        CREATE_SET: CREATE_SET
    };

})();