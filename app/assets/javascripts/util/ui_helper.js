/*
 Copyright Notice

 This is a work of the U.S. Government and is not subject to copyright
 protection in the United States. Foreign copyrights may apply.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */
/**
 * Created by gbowman on 2/8/2016.
 */
var UIHelper = (function () {

    var conceptClipboard = {};

    function getActiveTabId(tabControlId) {
        var id = "#" + tabControlId;
        var idx = $(id).tabs("option", "active");
        var tabpages = document.getElementById(tabControlId).children;

        if (idx >= 0 && idx <= tabpages.length - 1) {
            //add one to the index because the first child is the UL element for the tab labels. The remaining children are the tabpage divs
            return tabpages[parseInt(idx) + 1].id;
        }
        return undefined;
    }

    function isTabActive(tabControlId, tabpageId) {
        var tabpage = getActiveTabId(tabControlId);
        return (tabpage !== undefined ? (tabpage === tabpageId) : false);
    }

    function generateFormErrorMessage(message){
        return '<div class="komet-form-error"><div class="glyphicon glyphicon-alert"></div>' + message + '</div>';
    }

    function initializeContextMenus() {

        $.contextMenu({
            selector: '.komet-context-menu',
            build: function($triggerElement, e){

                var items = {};
                var menuType = $triggerElement.attr("data-menu-type");
                var menuState = $triggerElement.attr("data-menu-state");

                if (menuType == "sememe" || menuType == "concept" || menuType == "map_set"){

                    var uuid = $triggerElement.attr("data-menu-uuid");
                    var conceptText = $triggerElement.attr("data-menu-concept-text");

                    items.openConcept = {name:"Open in Concept Pane", icon: "context-menu-icon glyphicon-list-alt", callback: openConcept($triggerElement, uuid)};

                    if (WindowManager.viewers.inlineViewers.length < WindowManager.viewers.maxInlineViewers) {

                        items.openNewConceptViwer = {
                            name: "Open in New Concept Viewer",
                            icon: "context-menu-icon glyphicon-list-alt",
                            callback: openConcept($triggerElement, uuid, WindowManager.NEW)
                        };
                    }

                    if (menuType == "map_set"){

                        items.openMapSet = {name:"Open in Mapping Pane", icon: "context-menu-icon glyphicon-list-alt", callback: openMapSet($triggerElement, uuid)};

                        if (WindowManager.viewers.inlineViewers.length < WindowManager.viewers.maxInlineViewers) {

                            items.openNewMappingViwer = {
                                name: "Open in New Mapping Viewer",
                                icon: "context-menu-icon glyphicon-list-alt",
                                callback: openMapSet($triggerElement, uuid, WindowManager.NEW)
                            };
                        }
                    }

                    //items.openConceptNewWindow = {name:"Open in New Window", icon: "context-menu-icon glyphicon-list-alt", callback: openConcept($triggerElement, uuid, "popup")};

                    if (menuState == 'Active') {
                        items.activeInactiveUuid = {name:"InActive", icon: "context-menu-icon glyphicon-ok-circle", callback: activeInactiveConcept(uuid,'InActive')};
                    }
                    else {
                        items.activeInactiveUuid = {name:"Active", icon: "context-menu-icon glyphicon-ban-circle", callback: activeInactiveConcept(uuid,'Active')};
                    }

                    items.editConcept = {name:"Edit Concept", icon: "context-menu-icon glyphicon-plus", callback:  openConceptEditor($triggerElement, uuid, WindowManager.INLINE)};
                    items.cloneConcept = {name:"Clone Concept", icon: "context-menu-icon glyphicon-share", callback:  cloneConcept(uuid)};

                    if (conceptText != null || conceptText != undefined || conceptText != "") {

                        items.createChildConcept = {name:"Create Child", icon: "context-menu-icon glyphicon-plus", callback:  openConceptEditor($triggerElement, null, WindowManager.INLINE, uuid, conceptText)};
                        items.copyConcept = {name:"Copy Concept", icon: "context-menu-icon glyphicon-copy", callback: copyConcept(uuid, conceptText)};
                    }

                    items.copyUuid = {name: "Copy UUID", icon: "context-menu-icon glyphicon-copy", callback: copyToClipboard(uuid)};

                } else if (menuType == "paste_target"){

                    var idField = $triggerElement.attr("data-menu-id-field");
                    var displayField = $triggerElement.attr("data-menu-display-field");

                    if (conceptClipboard.id != undefined){
                        items.pasteConcept = {name: "Paste Concept: " + conceptClipboard.conceptText, isHtmlName: true, icon: "context-menu-icon glyphicon-paste", callback: pasteConcept(idField, displayField)}
                    }

                } else {
                    items.copy = {name:"Copy", icon: "context-menu-icon glyphicon-copy", callback: copyToClipboard($triggerElement.attr("data-menu-copy-value"))};
                }


                return {
                    callback: function(){},
                    items: items
                };
            },
        });
    }

    // Context menu functions

    function activeInactiveConcept(uuid,statusFlag) {
        return function (){
        params = {id: uuid,statusFlag:statusFlag } ;

                $.get( gon.routes.taxonomy_process_concept_ActiveInactive_path , params, function( results ) {
                    console.log(results);
                    TaxonomyModule.tree.reloadTreeStatedView($("#komet_taxonomy_stated_inferred")[0].value);
             });
        };
    }

    function cloneConcept(uuid) {

        return function (){

            params = {uuid: uuid} ;

            $.get( gon.routes.taxonomy_process_concept_Clone_path , params, function( results ) {
                console.log("Clone Concept " + uuid);
            });
        };
    }

    function copyConcept(id, conceptText){

        return function(){
            conceptClipboard = {id: id, conceptText: conceptText};
        };
    }

    function pasteConcept(idField, displayField){

        return function(){

            $("#" + idField).val(conceptClipboard.id);
            $("#" + displayField).val(conceptClipboard.conceptText);
        };
    }

    function copyToClipboard(text) {

        return function () {
            // have to create a fake element with the value on the page to get copy to work
            var textArea = document.createElement('textarea');
            textArea.setAttribute('style','width:1px;border:0;opacity:0;');
            document.body.appendChild(textArea);
            textArea.value = text;
            textArea.select();
            document.execCommand('copy');
            document.body.removeChild(textArea);
        };
    }

    function openConcept(element, id, windowType) {

        return function () {

            var stated;
            var viewerPanel = element.parents("div[id^=komet_viewer_]");
            var viewerID;

            if (viewerPanel.length > 0){
                viewerID = viewerPanel.first().attr("data-komet-viewer-id");
            } else{
                viewerID = WindowManager.getLinkedViewerID();
            }

            if (viewerPanel.length > 0){
                stated = WindowManager.viewers[viewerID].getStatedView();
            } else{
                stated = TaxonomyModule.getStatedView();
            }

            $.publish(KometChannels.Taxonomy.taxonomyTreeNodeSelectedChannel, ["", id, stated, viewerID, windowType]);
        };
    }

    function openConceptEditor(element, id, windowType, parentID, parentText) {

        return function () {

            var viewerPanel = element.parents("div[id^=komet_viewer_]");
            var viewerID;

            if (viewerPanel.length > 0) {
                viewerID = viewerPanel.first().attr("data-komet-viewer-id");
            } else {
                viewerID = WindowManager.getLinkedViewerID();
            }

            $.publish(KometChannels.Taxonomy.taxonomyConceptEditorChannel, [id, viewerID, windowType, {parentID: parentID, parentText: parentText}]);
        };
    }

    function openMapSet(element, id, windowType) {

        return function () {

            var viewerPanel = element.parents("div[id^=komet_viewer_]");
            var viewerID;

            if (viewerPanel.length > 0){
                viewerID = viewerPanel.first().attr("data-komet-viewer-id");
            } else{
                viewerID = WindowManager.getLinkedViewerID();
            }

            $.publish(KometChannels.Mapping.mappingTreeNodeSelectedChannel, ["", id, viewerID, windowType]);
        };
    }

    // function to switch a field between enabled and disabled
    function toggleFieldAvailability(field_name, enable){

        var field = $("#" + field_name);

        if (enable){

            field.removeClass("ui-state-disabled");
            field.addClass("ui-state-enabled");
        } else {

            field.removeClass("ui-state-enabled");
            field.addClass("ui-state-disabled");
        }
    }

    function hasFormChanged(formIdOrClass) {

        var hasChanges = false;

        $(formIdOrClass + " :input:not(:button):not([type=hidden])").each(function () {

            if ((this.type == "text" || this.type == "textarea" || this.type == "hidden") && this.defaultValue != this.value) {

                hasChanges = true;
                return false;             }
            else {

                if ((this.type == "radio" || this.type == "checkbox") && this.defaultChecked != this.checked) {

                    hasChanges = true;
                    return false;                 }
                else {

                    if ((this.type == "select-one" || this.type == "select-multiple")) {

                        for (var x = 0; x < this.length; x++) {

                            if (this.options[x].selected != this.options[x].defaultSelected) {

                                hasChanges = true;
                                return false;
                            }
                        }
                    }
                }
            }
        });

        return hasChanges;
    }

    function resetFormChanges(formIdOrClass) {

        $(formIdOrClass + " :input:not(:button):not([type=hidden])").each(function () {

            if (this.type == "text" || this.type == "textarea" || this.type == "hidden") {
                 this.value = this.defaultValue;

            } else if (this.type == "radio" || this.type == "checkbox") {
                this.checked = this.defaultChecked;

            } else if (this.type == "select-one" || this.type == "select-multiple") {

                for (var x = 0; x < this.length; x++) {
                    this.options[x].selected = this.options[x].defaultSelected;
                }
            }
        });
    }

    function acceptFormChanges(formIdOrClass) {

        $(formIdOrClass + " :input:not(:button):not([type=hidden])").each(function () {

            if (this.type == "text" || this.type == "textarea" || this.type == "hidden") {
                this.defaultValue = this.value;
            }
            if (this.type == "radio" || this.type == "checkbox") {
                this.defaultChecked = this.checked;
            }
            if (this.type == "select-one" || this.type == "select-multiple") {
                for (var x = 0; x < this.length; x++) {
                    this.options[x].defaultSelected = this.options[x].selected
                }
            }
        });
    }

    var findInArray = function (arrayToSearch, itemsToFind) {
        return itemsToFind.some(function (value) {
            return arrayToSearch.indexOf(value) >= 0;
        });
    };

    var createAutoSuggestField = function (fieldIDBase, fieldIDPostfix, label, fieldValue, fieldDisplayValue, fieldClasses, tabIndex) {

        if (fieldIDPostfix == null){
            fieldIDPostfix = "";
        }

        if (fieldValue == null){
            fieldValue = "";
        }

        if (fieldDisplayValue == null){
            fieldDisplayValue = "";
        }

        if (fieldClasses == null){
            fieldClasses = "";
        }

        var fieldTabIndex = ""
        var recentsTabIndex = ""

        if (tabIndex != null){

            fieldTabIndex = ' tabindex="' + tabIndex + '"';
            recentsTabIndex = ' tabindex="' + (tabIndex + 1) + '"';
        }

        var fieldString = '<label for="' + fieldIDBase + fieldIDPostfix + '">' + label + '</label>'
            + '<input id="' + fieldIDBase + fieldIDPostfix + '" name="' + fieldIDBase + '" class="hide" value="' + fieldValue + '">'
            + '<div id="' + fieldIDBase + '_fields' + fieldIDPostfix + '" class="input-group ' + fieldClasses + '">'
            + '<input id="' + fieldIDBase + '_display' + fieldIDPostfix + '" name="' + fieldIDBase + '_display" class="form-control komet-context-menu" '
            + 'data-menu-type="paste_target" data-menu-id-field="' + fieldIDBase + fieldIDPostfix + '" data-menu-display-field="' + fieldIDBase + '_display' + fieldIDPostfix + '" '
            + 'value="' + fieldDisplayValue + '"' + fieldTabIndex + '>'
            + '<div class="input-group-btn komet-search-combo-field">'
            + '<button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false"><span class="caret"></span></button>'
            + '<ul id="' + fieldIDBase + '_recents' + fieldIDPostfix + '" class="dropdown-menu dropdown-menu-right"' + recentsTabIndex + '></ul>'
            + '</div></div>';


        // create and return a dom fragment from the field string
        return document.createRange().createContextualFragment(fieldString);
    };

    var processAutoSuggestTags = function(containerClassOrID){

        var tags = $(containerClassOrID).find("autosuggest");

        tags.each(function(i, tag){

            var fieldIDBase = tag.getAttribute("id-base");
            var fieldIDPostfix = tag.getAttribute("id-postfix");
            var label = tag.getAttribute("label");
            var fieldValue = tag.getAttribute("value");
            var fieldDisplayValue = tag.getAttribute("display-value");
            var fieldClasses = tag.getAttribute("classes");
            var tabIndex = tag.getAttribute("tab-index");
            var suggestionRestVariable = tag.getAttribute("suggestion-rest-variable");
            var recentsRestVariable = tag.getAttribute("recents-rest-variable");

            if (fieldIDPostfix == null){
                fieldIDPostfix = "";
            }

            if (suggestionRestVariable == null){
                suggestionRestVariable = "komet_dashboard_get_concept_suggestions_path";
            }

            var autoSuggest = UIHelper.createAutoSuggestField(fieldIDBase, fieldIDPostfix, label, fieldValue, fieldDisplayValue, fieldClasses, tabIndex);

            $(tag).replaceWith(autoSuggest);

            var displayField = $("#" + fieldIDBase + "_display" + fieldIDPostfix);

            displayField.autocomplete({
                source: gon.routes[suggestionRestVariable],
                minLength: 3,
                select: onAutoSuggestSelection,
                change: onAutoSuggestChange
            });

            loadAutoSuggestRecents(fieldIDBase + "_recents" + fieldIDPostfix, recentsRestVariable);
        });
    };

    var loadAutoSuggestRecents = function(recentsID, restVariable){

        if (restVariable == null){
            restVariable = "komet_dashboard_get_concept_recents_path";
        }

        $.get(gon.routes[restVariable], function (data) {

            var options = "";

            $.each(data, function (index, value) {

                var autoSuggestID = recentsID.replace("_recents", "_display");
                var autoSuggestDisplayID = recentsID.replace("_recents", "");

                // use the html function to escape any html that may have been entered by the user
                var valueText = $("<li>").text(value.text).html();
                options += "<li><a href=\"#\" onclick=\"UIHelper.useAutoSuggestRecent('" + autoSuggestID + "', '" + autoSuggestDisplayID + "', '" + value.id + "', '" + valueText + "')\">" + valueText + "</a></li>";
            });

            $("#" + recentsID).html(options);
        });
    };

    var useAutoSuggestRecent = function(autoSuggestID, autoSuggestDisplayID, id, text){

        var labelField = $("#" + autoSuggestID);
        labelField.val(text);
        labelField.change();

        var idField = $("#" + autoSuggestDisplayID)
        idField.val(id);
        idField.change();
    };

    var onAutoSuggestSelection = function(event, ui){

        var labelField = $(this);
        labelField.val(ui.item.label);
        labelField.change();

        var idField = $("#" + this.id.replace("_display", ""))
        idField.val(ui.item.value);
        idField.change();

        return false;
    };

    var onAutoSuggestChange = function(event, ui){

        if (!ui.item) {

            var labelField = $(this);
            labelField.val("");
            labelField.change();

            var idField = $("#" + this.id.replace("_display", ""))
            idField.val("");
            idField.change();
        }
    };

    return {
        getActiveTabId: getActiveTabId,
        isTabActive: isTabActive,
        initializeContextMenus: initializeContextMenus,
        generateFormErrorMessage: generateFormErrorMessage,
        toggleFieldAvailability: toggleFieldAvailability,
        hasFormChanged: hasFormChanged,
        resetFormChanges: resetFormChanges,
        acceptFormChanges: acceptFormChanges,
        findInArray: findInArray,
        createAutoSuggestField: createAutoSuggestField,
        processAutoSuggestTags: processAutoSuggestTags,
        loadAutoSuggestRecents: loadAutoSuggestRecents,
        useAutoSuggestRecent: useAutoSuggestRecent
    };
})();


