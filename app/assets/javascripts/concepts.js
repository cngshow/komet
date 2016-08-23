var ConceptsModule = (function () {

    var panelStates = {};
    var viewers = {};
    viewers.inlineViewers = [];
    viewers.maxInlineViewers = 2;
    var viewerMode = "single";
    var loading = false;

    function subscribeToTaxonomyTree() {

        // listen for the onChange event broadcast by any of the taxonomy this.trees.
        $.subscribe(KometChannels.Taxonomy.taxonomyTreeNodeSelectedChannel, function (e, treeID, conceptID, stated, viewerID, windowType) {

            if (WindowManager.deferred && WindowManager.deferred.state() == "pending"){
                WindowManager.deferred.done(function(){
                    ConceptsModule.loadViewerData(conceptID, stated, WindowManager.getLinkedViewerID(), windowType)
                }.bind(this));
            } else {
                ConceptsModule.loadViewerData(conceptID, stated, viewerID, windowType);
            }
        });
    }

    function subscribeToSearch() {

        // listen for the onChange event broadcast by selecting a search result.
        $.subscribe(KometChannels.Taxonomy.taxonomySearchResultSelectedChannel, function (e, conceptID, viewerID, windowType) {

            ConceptsModule.loadViewerData(conceptID, TaxonomyModule.defaultStatedView, viewerID, windowType);
        });
    }

    function loadViewerData(conceptID, stated, viewerID, windowType) {

        loading = true;
        WindowManager.deferred = $.Deferred();

        if (WindowManager.viewers.inlineViewers.length == 0 || WindowManager.getLinkedViewerID() == WindowManager.NEW){
            windowType = WindowManager.NEW;
        }

        // the path to a javascript partial file that will re-render all the appropriate partials once the ajax call returns
        var partial = 'komet_dashboard/concept_detail/concept_information';

        // make an ajax call to get the concept for the current concept and pass it the currently selected concept id and the name of a partial file to render
        $.get(gon.routes.taxonomy_get_concept_information_path, {
            concept_id: conceptID,
            stated: stated,
            partial: partial,
            viewer_id: viewerID
        }, function (data) {

            try {

                WindowManager.loadViewerData(data, viewerID, "concept", windowType);

                if (windowType != WindowManager.NEW && windowType != WindowManager.POPUP) {

                    WindowManager.viewers[viewerID].refsetGridOptions = null;
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
    function subscribeToAddEditConcept()
    {
        // listen for the onChange event broadcast by selecting a search result.
        $.subscribe(KometChannels.Taxonomy.taxonomyAddEditConceptChannel, function (e,conceptID, viewerID, windowType) {

            ConceptsModule.loadConceptPanel(conceptID,TaxonomyModule.defaultStatedView, viewerID, windowType);
        });
    }

    function loadConceptPanel(conceptID, stated, viewerID, windowType) {

        loading = true;
        deferred = $.Deferred();
        // if (WindowManager.viewers.inlineViewers.length == 0 || WindowManager.getLinkedViewerID() == WindowManager.NEW){
        windowType = WindowManager.INLINE;
        //}
        // the path to a javascript partial file that will re-render all the appropriate partials once the ajax call returns
        var partial = 'komet_dashboard/concept_add_edit';
         // make an ajax call to get the concept for the current concept and pass it the currently selected concept id and the name of a partial file to render
        $.get(gon.routes.taxonomy_get_concept_add_edit_path, {
            concept_id: conceptID,
            stated: stated,
            partial: partial,
            viewer_id: viewerID
        }, function (data) {

            try {

                WindowManager.loadViewerData(data, viewerID, "concept", windowType);
                    deferred.resolve();

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
        WindowManager.deferred.resolve();
    }

    function setStatedView(viewerID, field) {
        loadViewerData(WindowManager.viewers[viewerID].currentConceptID, field.value, viewerID);
    }
    function onLineageSuggestionSelection(event, ui){

        $("#taxonomy_lineage_display").val(ui.item.label);
        $("#taxonomy_lineage_id").val(ui.item.value);
        return false;
    }

    function onLineageSuggestionChange(event, ui){

        if (!ui.item){
            event.target.value = "";
            $("#taxonomy_lineage_id").val("");
        }
    }
    function init() {

        subscribeToTaxonomyTree();
        subscribeToSearch();
        subscribeToAddEditConcept();

        $("#txtName").keyup(function(event) {
            var stt = $(this).val();
            $("taxonomy_pn_text").text(stt);
            $("taxonomy_fsn_text").text(stt);
        });

        $("#taxonomy_lineage_display").keyup(function(event) {
            var stt =  $("taxonomy_pn_text").text() + $(this).val();

            $("taxonomy_fsn_text").text(stt);
        });

        // setup the assemblage field autocomplete functionality
        $("#taxonomy_lineage_display").autocomplete({
            source: gon.routes.search_get_assemblage_suggestions_path,
            minLength: 3,
            select: onLineageSuggestionSelection,
            change: onLineageSuggestionChange
        });

        // load any previous assemblage queries into a menu for the user to select from
       // loadLineageRecents();
    }

    function loadLineageRecents() {

        $.get(gon.routes.search_get_assemblage_recents_path, function (data) {

            var options = "";

            $.each(data, function (index, value) {

                // use the html function to escape any html that may have been entered by the user
                var valueText = $("<li>").text(value.text).html();
                options += "<li><a href=\"#\" onclick=\"TaxonomySearchModule.useLineageRecent('" + value.id + "', '" + valueText + "')\">" + valueText + "</a></li>";
            });

            $("#taxonomy_lineage_recents").html(options);
        });
    }

    function useLineageRecent(id, text){

        $("#taxonomy_lineage_display").val(text);
        $("#taxonomy_lineage_id").val(id);
    }
    return {
        initialize: init,
        createViewer: createViewer,
        loadViewerData: loadViewerData,
        setStatedView: setStatedView,
        viewers: viewers,
        loadConceptPanel:loadConceptPanel,
        useLineageRecent: useLineageRecent
    };

})();
