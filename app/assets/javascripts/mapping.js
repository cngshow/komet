var MappingModule = (function () {

    const SET_LIST = 'set_list';
    const SET_DETAILS = 'set_details';
    const SET_EDITOR = 'set_editor';
    const ITEM_EDITOR = 'item_editor';

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

            viewerID = WindowManager.getLinkedViewerID();

            var action;

            if (setID == null || setID == 0){
                action = SET_LIST;
            } else {
                action = SET_DETAILS;
            }

            if (WindowManager.deferred && WindowManager.deferred.state() == "pending"){
                WindowManager.deferred.done(function(){
                    MappingModule.loadViewerData(setID, action, WindowManager.getLinkedViewerID(), windowType)
                }.bind(this));
            } else {
                MappingModule.loadViewerData(setID, action, viewerID, windowType);
            }
        });
    }

    // the path to a javascript partial file that will re-render all the appropriate partials once the ajax call returns
    function loadViewerData(set_id, mapping_action, viewerID, windowType) {

        WindowManager.deferred = $.Deferred();

        var params = {partial: 'komet_dashboard/mapping/mapping_viewer', mapping_action: mapping_action, viewer_id: viewerID, set_id: set_id};
        var url = gon.routes.mapping_load_mapping_viewer_path;

        if (mapping_action == "set_details"){

        }

        if (WindowManager.viewers.inlineViewers.length == 0 || WindowManager.getLinkedViewerID() == WindowManager.NEW){
            windowType = WindowManager.NEW;
        }


        // make an ajax call to get the concept for the current concept and pass it the currently selected concept id and the name of a partial file to render
        $.get(url, params, function (data) {

            try {

                WindowManager.loadViewerData(data, viewerID, "mapping", windowType);

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

    function createViewer(viewerID, setID) {

        WindowManager.createViewer(new MappingViewer(viewerID, setID));
        WindowManager.deferred.resolve();
    }

    function openSetEditor(newSet) {

        var url = gon.routes.mapping_map_set_editor_path;

        if (!newSet) {
            url += "?set_id=" + overviewSetsGridOptions.api.getSelectedRows()[0].id;
        }

        setEditorWindow = window.open(url, "MapSetEditor", "width=600,height=330");
    }

    return {
        initialize: init,
        loadViewerData: loadViewerData,
        createViewer: createViewer,
        openSetEditor: openSetEditor,
        SET_LIST: SET_LIST,
        SET_DETAILS: SET_DETAILS,
        SET_EDITOR: SET_EDITOR,
        ITEM_EDITOR: ITEM_EDITOR
    };

})();