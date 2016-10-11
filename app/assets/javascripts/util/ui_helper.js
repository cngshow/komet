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
    const VHAT = "vhat";
    const SNOMED = "snomed";
    const LOINC = "loinc";
    const RXNORM = "rxnorm";
    const CHANGEABLE_CLASS = "komet-changeable";
    const CHANGE_HIGHLIGHT_CLASS = "komet-highlight-changes";

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

    function generateFormErrorMessage(message, formLevelError){

        var classLevel = "komet-form-field-error";

        if (formLevelError != undefined && formLevelError){
            classLevel = "komet-form-error";
        }

        return '<div class="' + classLevel + '"><div class="glyphicon glyphicon-alert"></div>' + message + '</div>';
    }

    function generateConfirmationDialog(title, message, closeCallback, buttonText, positioningElementOrSelector, formID) {

        var dialogID = "komet_generated_confirm_dialog";
        var body = $("body");
        var position = {my: "center", at: "center", of: body};
        var buttonClicked = "cancel";
        var buttonType = "button";
        var dialogString = '<div id="' + dialogID + '"><div class="komet-confimation-dialog-message">' + message + '</div></div>';

        if (buttonText == undefined || buttonText == null) {
            buttonText = "Yes";
        }

        if (positioningElementOrSelector != undefined && positioningElementOrSelector != null) {

            var element;

            // If the type of the second parameter is a string, then use it as a jquery selector, otherwise use as is
            if (typeof positioningElementOrSelector === "string") {
                element = $(positioningElementOrSelector);
            } else {
                element = positioningElementOrSelector;
            }

            position = {my: "right bottom", at: "left bottom", of: element};
        }

        if (formID == undefined){
            formID = null;
        } else {
            buttonType = "submit";
        }

        body.prepend(dialogString);

        var dialog = $("#" + dialogID);

        dialog.dialog({
            beforeClose: function(e) { closeCallback(buttonClicked); dialog.remove();},
            title: title,
            resizable: false,
            height: "auto",
            width: 400,
            modal: true,
            position: position,
            dialogClass: "komet-confirmation-dialog komet-dialog-no-close-button",
            buttons:{
                Cancel: {
                    "class": "btn btn-default",
                    text: "Cancel",
                    click: function () {
                        $(this).dialog("close");
                    }
                },
                OK: {
                    "autofocus": "true",
                    text: buttonText,
                    "class": "btn btn-primary",
                    click: function () {

                        buttonClicked = buttonText;
                        $(this).dialog("close");
                    }//,
                    //type: buttonType,
                    //form: formID
                }
            }
        });
    }

    function toggleChangeHighlights(containerElementOrSelector, showChanges) {

        var element;

        // If the type of the first parameter is a string, then use it as a jquery selector, otherwise use as is
        if (typeof containerElementOrSelector === "string"){
            element = $(containerElementOrSelector);
        } else {
            element = containerElementOrSelector;
        }

        var tags = element.find(".komet-changeable");

        if (showChanges){
            tags.addClass("komet-highlight-changes");
        } else {
            tags.removeClass("komet-highlight-changes");
        }
    }

    // function to switch a field between enabled and disabled
    function toggleFieldAvailability(elementOrSelector, enable){

        var element;

        // If the type of the first parameter is a string, then use it as a jquery selector, otherwise use as is
        if (typeof elementOrSelector === "string"){
            element = $(elementOrSelector);
        } else {
            element = elementOrSelector;
        }

        if (enable){

            element.removeClass("ui-state-disabled");
            element.addClass("ui-state-enabled");
        } else {

            element.removeClass("ui-state-enabled");
            element.addClass("ui-state-disabled");
        }
    }

    /*
     * hasFormChanged - Check to see if there were changes in a form, optionally returning the change details and highlighting them.
     * @param [object or string] formElementOrSelector - Either a jquery object or the class or ID selector (including the "#" or "." prefix) that respresents the form to search for changes.
     * @param [boolean] returnChanges - Should an array of changes be returned (true), or simply true/false (false). If this and highlightChanges
     *                                  are false then the function will only loop until it finds the first change. (Optional: default = false)
     * @param [boolean] highlightChanges - Should changes be highlighted. Requires the "komet-highlight-changes" class on the elements you want highlighted. (Optional: default = false)
     * @return [array or boolean] - If returnChanges is true, returns an array containing a hash of each fields changes ({field, oldValue, newValue}), otherwise returns true or false.
     */
    function hasFormChanged(formElementOrSelector, returnChanges, highlightChanges) {

        var changes = [];
        var element;

        // set the default value if this optional parameter wasn't passed in
        if (returnChanges == undefined){
            returnChanges = false;
        }

        // set the default value if this optional parameter wasn't passed in
        if (highlightChanges == undefined){
            highlightChanges = false;
        }

        // If the type of the first parameter is a string, then use it as a jquery selector, otherwise use as is
        if (typeof formElementOrSelector === "string"){
            element = $(formElementOrSelector);
        } else {
            element = formElementOrSelector;
        }

        // find all non-hidden form fields and loop through them
        element.find(":input:not(:button):not([type=hidden])").each(function () {

            // store the name of the field, and two empty arrays we can easily check later to see if changes were found
            // doing it this way allows for less code in the select box section
            var field = {field: this.name, oldValue: [], newValue: []};

            // if the field is a text field and the old value and new value dont match store the changes
            if ((this.type == "text" || this.type == "textarea") && this.defaultValue != this.value) {

                field = {field: this.name, oldValue: this.defaultValue, newValue: this.value};

            // if the field is a radio or checkbox and the old value and new value dont match store the changes, including the type because it could be part of a field group
            } else if ((this.type == "radio" || this.type == "checkbox") && this.defaultChecked != this.checked) {

                field = {field: this.name, oldValue: this.defaultChecked, newValue: this.checked, type: this.type};

            // if the field is a select box
            } else if ((this.type == "select-one" || this.type == "select-multiple")) {

                // loop through the select's options
                for (var i = 0; i < this.length; i++) {

                    // if the option's old selected value and new selected value dont match store the changes
                    if (this.options[i].selected != this.options[i].defaultSelected) {

                        // if this is a single selection select box
                        if (this.type == "select-one"){

                            // if the old selected value was true then this is the old value, otherwise it's the new value
                            if (this.options[i].defaultSelected){
                                field.oldValue = this.options[i].value;
                            } else {

                                field.newValue = this.options[i].value;

                                // if the old value is still an empty array, set it to an empty string, because it may have never had a value selected
                                if (typeof field.oldValue == "object"){
                                    field.oldValue = "";
                                }
                            }

                        } else {

                            // if this is a multi selection select box then we need to store values as an array
                            // if the old selected value was true then this is the old value, otherwise it's the new value
                            if (this.options[i].defaultSelected){
                                field.oldValue.push(this.options[i].value);
                            } else {
                                field.newValue.push(this.options[i].value);
                            }
                        }
                    }
                }
            }

            // check to see if field's new value is an empty array. If it isn't then the field changed
            if (!(typeof field.oldValue == "object" && field.oldValue.length === 0 && typeof field.newValue == "object" && field.newValue.length === 0)) {

                // if we are not returning the array of changes or highlighting them, then we can stop looping and return true
                if (!returnChanges && !highlightChanges){
                    return true;
                }

                // add the field to the changes array
                changes.push(field);

                // if we are highlighting changes then find the nearest element with the changeable class, and add the hightlight class
                if (highlightChanges){
                    $(this).closest(".komet-changeable").addClass("komet-highlight-changes");
                }
            }
        });

        // if we are not returning the array of changes then check to see if there were changes
        if (!returnChanges){

            if (changes.length > 0){
                return true;
            } else {
                return false;
            }
        }

        // return the array of changes
        return changes;
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

    function acceptFormChanges(formElementOrSelector) {

        var element;

        // If the type of the first parameter is a string, then use it as a jquery selector, otherwise use as is
        if (typeof formElementOrSelector === "string"){
            element = $(formElementOrSelector);
        } else {
            element = formElementOrSelector;
        }

        element.find(":input:not(:button):not([type=hidden])").each(function () {

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

    var createAutoSuggestField = function (fieldIDBase, fieldIDPostfix, label, name, nameFormat, idValue, displayValue, typeValue, fieldClasses, tabIndex) {

        if (fieldIDPostfix == null){
            fieldIDPostfix = "";
        }

        if (label == null){
            label = "";
        } else {
            label = '<label for="' + fieldIDBase + fieldIDPostfix + '">' + label + '</label>';
        }

        var idName = fieldIDBase;
        var typeName = fieldIDBase + "_type";
        var displayName = fieldIDBase + "_display";

        if (name != null){

            if (nameFormat == "array"){

                idName = name + "]";
                typeName = name + "_type]";
                displayName = name + "_display]";

            } else {

                idName = name;
                typeName = name + "_type";
                displayName = name + "_display";
            }
        }

        if (idValue == null){
            idValue = "";
        }

        if (displayValue == null){
            displayValue = "";
        }

        if (typeValue == null){
            typeValue = "";
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

        // use the hide class to hide the ID and Type fields so that the hasFormChanged() function can pick up the changed values.
        var fieldString = label + '<input id="' + fieldIDBase + fieldIDPostfix + '" name="' + idName + '" class="hide" value="' + idValue + '">'
            + '<input id="' + fieldIDBase + '_type' + fieldIDPostfix + '" name="' + typeName + '" class="hide" value="' + typeValue + '">'
            + '<div id="' + fieldIDBase + '_fields' + fieldIDPostfix + '" class="komet-autosuggest input-group ' + fieldClasses + '">'
            + '<input id="' + fieldIDBase + '_display' + fieldIDPostfix + '" name="' + displayName + '" class="form-control komet-context-menu" '
            + 'data-menu-type="paste_target" data-menu-id-field="' + fieldIDBase + fieldIDPostfix + '" data-menu-display-field="' + fieldIDBase + '_display' + fieldIDPostfix + '" '
            + 'data-menu-taxonomy-type-field="' + fieldIDBase + '_type' + fieldIDPostfix + '" value="' + displayValue + '"' + fieldTabIndex + '>'
            + '<div id="' + fieldIDBase + '_recents_button' + fieldIDPostfix + '"  class="input-group-btn komet-search-combo-field">'
            + '<button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false"><span class="caret"></span></button>'
            + '<ul id="' + fieldIDBase + '_recents' + fieldIDPostfix + '" class="dropdown-menu dropdown-menu-right"' + recentsTabIndex + '></ul>'
            + '</div></div>';

        // create and return a dom fragment from the field string
        return document.createRange().createContextualFragment(fieldString);
    };

    var processAutoSuggestTags = function(containerElementOrSelector){

        var element;

        // If the type of the first parameter is a string, then use it as a jquery selector, otherwise use as is
        if (typeof containerElementOrSelector === "string"){
            element = $(containerElementOrSelector);
        } else {
            element = containerElementOrSelector;
        }

        var tags = $(element).find("autosuggest");

        tags.each(function(i, tag){

            var fieldIDBase = tag.getAttribute("id-base");
            var fieldIDPostfix = tag.getAttribute("id-postfix");
            var label = tag.getAttribute("label");
            var name = tag.getAttribute("name");
            var nameFormat = tag.getAttribute("name-format");
            var idValue = tag.getAttribute("value");
            var displayValue = tag.getAttribute("display-value");
            var typeValue = tag.getAttribute("type-value");
            var fieldClasses = tag.getAttribute("classes");
            var tabIndex = tag.getAttribute("tab-index");
            var suggestionOnChangeFunction = tag.getAttribute("suggestion-onchange-function");
            var suggestionRestVariable = tag.getAttribute("suggestion-rest-variable");
            var recentsRestVariable = tag.getAttribute("recents-rest-variable");

            if (fieldIDPostfix == null){
                fieldIDPostfix = "";
            }

            if (suggestionRestVariable == null){
                suggestionRestVariable = "komet_dashboard_get_concept_suggestions_path";
            }

            if (suggestionOnChangeFunction == null){
                suggestionOnChangeFunction = "";
            }

            var autoSuggest = UIHelper.createAutoSuggestField(fieldIDBase, fieldIDPostfix, label, name, nameFormat, idValue, displayValue, typeValue, fieldClasses, tabIndex);

            $(tag).replaceWith(autoSuggest);

            var displayField = $("#" + fieldIDBase + "_display" + fieldIDPostfix);

            var asOnChange = function (suggestionOnChangeFunction) {

                return function(){
                    setTimeout(suggestionOnChangeFunction, 0);
                };
            };

            //displayField.change(asOnChange(suggestionOnChangeFunction));

            displayField.autocomplete({
                source: gon.routes[suggestionRestVariable],
                minLength: 3,
                select: onAutoSuggestSelection
                ,change: onAutoSuggestChange(suggestionOnChangeFunction)
            });

            var recentsButton = $("#" + fieldIDBase + "_recents_button" + fieldIDPostfix);

            recentsButton.on('show.bs.dropdown', function () {

                var menu = $("#" + fieldIDBase + "_recents" + fieldIDPostfix);
                menu.css("position", "fixed");
                menu.css("top", recentsButton.offset().top + recentsButton.height());
                menu.css("right", getElementRightFromWindow(recentsButton));
            }.bind(this));

            loadAutoSuggestRecents(fieldIDBase + "_recents" + fieldIDPostfix, recentsRestVariable, suggestionOnChangeFunction);
        });
    };

    var onAutoSuggestSelection = function(event, ui){

        var labelField = $(this);
        labelField.val(ui.item.label);
        labelField.change();

        var idField = $("#" + this.id.replace("_display", ""));
        idField.val(ui.item.value);
        idField.change();

        var typeField = $("#" + this.id.replace("_display", "_type"));
        typeField.val(ui.item.type);
        typeField.change();

        return false;
    };

    var onAutoSuggestChange = function(suggestionOnChangeFunction){

        return function(event, ui) {

            if (!ui.item) {

                var idField = $("#" + this.id.replace("_display", ""));
                idField.val("");
                idField.change();

                var typeField = $("#" + this.id.replace("_display", "_type"));
                typeField.val("");
                typeField.change();

                // make sure this is last, as there may be an onchange event on the display field that requires the other fields to be set.
                // though since onchange events for this field run before the autosuggest finishes updating all fields, also run the user supplied change function
                var labelField = $(this);
                labelField.val("");
                labelField.change();
            }

            // run the user supplied onchange function if there is one
            //setTimeout(suggestionOnChangeFunction, 0);
        };
    };

    var loadAutoSuggestRecents = function(recentsID, restVariable, suggestionOnChangeFunction){

        if (restVariable == null){
            restVariable = "komet_dashboard_get_concept_recents_path";
        }

        $.get(gon.routes[restVariable], function (data) {

            var options = "";

            $.each(data, function (index, value) {

                var autoSuggestIDField = recentsID.replace("_recents", "");
                var autoSuggestDisplayField = recentsID.replace("_recents", "_display");
                var autoSuggestTypeField = recentsID.replace("_recents", "_type");

                // use the html function to escape any html that may have been entered by the user
                var valueText = $("<li>").text(value.text).html();

                // TODO - remove this reassignment when the type flags are implemented in the REST APIs
                value.type = UIHelper.VHAT;

                options += '<li><a href="#" onclick=\'UIHelper.useAutoSuggestRecent("' + autoSuggestIDField + '", "' + autoSuggestDisplayField + '", "' + autoSuggestTypeField + '"'
                    + ', "' + value.id + '", "' + valueText + '", "' + value.type + '", "' + suggestionOnChangeFunction + '")\'>' + valueText + '</a></li>';
            });

            $("#" + recentsID).html(options);
        });
    };

    var useAutoSuggestRecent = function(autoSuggestID, autoSuggestDisplayField, autoSuggestTypeField, id, text, type, suggestionOnChangeFunction){

        var idField = $("#" + autoSuggestID);
        idField.val(id);
        idField.change();

        var typeField = $("#" + autoSuggestTypeField);
        typeField.val(type);
        typeField.change();

        // make sure this is last, as there may be an onchange event on the display field that requires the other fields to be set.
        // though since onchange events for this field run before the autosuggest finishes updating all fields, also run the user supplied change function
        var displayField = $("#" + autoSuggestDisplayField);
        displayField.val(text);
        displayField.change();

        // run the user supplied onchange function if there is one
        //setTimeout(suggestionOnChangeFunction, 0);
    };

    var getElementRightFromWindow = function(elementOrSelector){

        var element;

        // If the type of the first parameter is a string, then use it as a jquery selector, otherwise use as is
        if (typeof elementOrSelector === "string"){
            element = $(elementOrSelector);
        } else {
            element = elementOrSelector;
        }

        if (element.length > 0){
            return($(window).width() - (element.offset().left + element.outerWidth()));
        } else {
            return null;
        }
    };

    // TODO - Fix z-index of menus in IE - splitter bars cutting through it
    function initializeContextMenus() {

        $.contextMenu({
            selector: '.komet-context-menu',
            build: function($triggerElement, e){

                var items = {};
                var menuType = $triggerElement.attr("data-menu-type");

                if (menuType == "sememe" || menuType == "concept" || menuType == "map_set"){

                    var uuid = $triggerElement.attr("data-menu-uuid");
                    var conceptText = $triggerElement.attr("data-menu-concept-text");
                    var conceptTerminologyType = $triggerElement.attr("data-menu-concept-terminology-type");
                    var conceptState = $triggerElement.attr("data-menu-state");
                    var unlinkedViewerID = WindowManager.getUnlinkedViewerID();

                    if (conceptText == undefined || conceptText == ""){
                        conceptText = null;
                    }

                    if (conceptState == undefined || conceptState == ""){
                        conceptState = null;
                    }

                    if (conceptTerminologyType == undefined || conceptTerminologyType == ""){
                        conceptTerminologyType = null;
                    }

                    items.openConcept = {name:"Open Concept", icon: "context-menu-icon glyphicon-list-alt", callback: openConcept($triggerElement, uuid)};

                    if (WindowManager.viewers.inlineViewers.length < WindowManager.viewers.maxInlineViewers) {

                        items.openNewConceptViwer = {
                            name: "Open in New Concept Viewer",
                            icon: "context-menu-icon glyphicon-list-alt",
                            callback: openConcept($triggerElement, uuid, WindowManager.NEW, WindowManager.NEW)
                        };
                    }

                    if (WindowManager.viewers.inlineViewers.length > 1) {

                        items.openUnlinkedConceptViwer = {
                            name: "Open in Unlinked Concept Viewer",
                            icon: "context-menu-icon glyphicon-list-alt",
                            callback: openConcept($triggerElement, uuid, unlinkedViewerID)
                        };
                    }

                    //items.openConceptNewWindow = {name:"Open in New Window", icon: "context-menu-icon glyphicon-list-alt", callback: openConcept($triggerElement, uuid, "popup")};

                    if (menuType == "map_set"){

                        items.separatorMapping = {type: "cm_separator"};

                        items.openMapSet = {name:"Open Mapping", icon: "context-menu-icon glyphicon-list-alt", callback: openMapSet($triggerElement, uuid)};

                        if (WindowManager.viewers.inlineViewers.length < WindowManager.viewers.maxInlineViewers) {

                            items.openNewMappingViwer = {
                                name: "Open in New Mapping Viewer",
                                icon: "context-menu-icon glyphicon-list-alt",
                                callback: openMapSet($triggerElement, uuid, WindowManager.NEW, WindowManager.NEW)
                            };
                        }

                        if (WindowManager.viewers.inlineViewers.length > 1) {

                            items.openUnlinkedMappingViwer = {
                                name: "Open in Unlinked Mapping Viewer",
                                icon: "context-menu-icon glyphicon-list-alt",
                                callback: openMapSet($triggerElement, uuid, unlinkedViewerID)
                            };
                        }
                    }

                    items.separatorCopy = {type: "cm_separator"};

                    if (conceptText != null && conceptTerminologyType != null) {
                        items.copyConcept = {name:"Copy Concept", icon: "context-menu-icon glyphicon-copy", callback: copyConcept(uuid, conceptText, conceptTerminologyType)};
                    }

                    items.copyUuid = {name: "Copy UUID", icon: "context-menu-icon glyphicon-copy", callback: copyToClipboard(uuid)};

                    items.separatorConceptEditor = {type: "cm_separator"};

                    items.editConcept = {name:"Edit Concept", icon: "context-menu-icon glyphicon-pencil", callback:  openConceptEditor($triggerElement, uuid)};

                    if (WindowManager.viewers.inlineViewers.length < WindowManager.viewers.maxInlineViewers) {

                        items.editConceptNewViewer = {
                            name:"Edit Concept in New Viewer",
                            icon: "context-menu-icon glyphicon-pencil",
                            callback:  openConceptEditor($triggerElement, uuid, WindowManager.NEW, WindowManager.NEW)
                        };
                    }

                    if (WindowManager.viewers.inlineViewers.length > 1) {

                        items.editConceptUnlinkedViewer = {
                            name:"Edit Concept in Unlinked Viewer",
                            icon: "context-menu-icon glyphicon-pencil",
                            callback:  openConceptEditor($triggerElement, uuid, unlinkedViewerID)
                        };
                    }

                    items.cloneConcept = {name:"Clone Concept", icon: "context-menu-icon glyphicon-share", callback:  cloneConcept(uuid)};

                    if (conceptText != null && conceptTerminologyType != null) {

                        items.createChildConcept = {
                            name:"Create Child Concept",
                            icon: "context-menu-icon glyphicon-plus",
                            callback:  openConceptEditor($triggerElement, null, WindowManager.getLinkedViewerID(), WindowManager.INLINE, uuid, conceptText, conceptTerminologyType)
                        };

                        if (WindowManager.viewers.inlineViewers.length < WindowManager.viewers.maxInlineViewers) {

                            items.createChildConceptNewViewer = {
                                name:"Create Child Concept in New Viewer",
                                icon: "context-menu-icon glyphicon-plus",
                                callback:  openConceptEditor($triggerElement, null, WindowManager.NEW, WindowManager.NEW, uuid, conceptText, conceptTerminologyType)
                            };
                        }

                        if (WindowManager.viewers.inlineViewers.length > 1) {

                            items.createChildConceptUnlinkedViewer = {
                                name:"Create Child Concept in Unlinked Viewer",
                                icon: "context-menu-icon glyphicon-plus",
                                callback:  openConceptEditor($triggerElement, null, unlinkedViewerID, WindowManager.INLINE, uuid, conceptText, conceptTerminologyType)
                            };
                        }
                    }

                    if (conceptState != null) {

                        items.separatorState = {type: "cm_separator"};

                        if (conceptState == 'Active') {
                            items.activeInactiveUuid = {
                                name: "Inactivate Concept",
                                icon: "context-menu-icon glyphicon-ban-circle",
                                callback: changeConceptState(uuid, 'InActive')
                            };
                        } else {
                            items.activeInactiveUuid = {
                                name: "Activate Concept",
                                icon: "context-menu-icon glyphicon-ok-circle",
                                callback: changeConceptState(uuid, 'Active')
                            };
                        }
                    }

                } else if (menuType == "paste_target") {

                    var idField = $triggerElement.attr("data-menu-id-field");
                    var displayField = $triggerElement.attr("data-menu-display-field");
                    var typeField = $triggerElement.attr("data-menu-taxonomy-type-field");

                    if (conceptClipboard.id != undefined){
                        items.pasteConcept = {name: "Paste Concept: " + conceptClipboard.conceptText, isHtmlName: true, icon: "context-menu-icon glyphicon-paste", callback: pasteConcept(idField, displayField, typeField)}
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

    function openConcept(element, id, viewerID, windowType) {

        return function () {

            var stated;
            var viewerPanel = element.parents("div[id^=komet_viewer_]");

            // if the viewerID was not passed it (but not if it is null), look up what it should be
            if (viewerID === undefined) {

                if (viewerPanel.length > 0) {
                    viewerID = viewerPanel.first().attr("data-komet-viewer-id");
                } else {
                    viewerID = WindowManager.getLinkedViewerID();
                }
            }

            if (viewerPanel.length > 0){
                stated = WindowManager.viewers[viewerID].getStatedView();
            } else{
                stated = TaxonomyModule.getStatedView();
            }

            $.publish(KometChannels.Taxonomy.taxonomyTreeNodeSelectedChannel, ["", id, stated, viewerID, windowType]);
        };
    }

    function openMapSet(element, id, viewerID, windowType) {

        return function () {

            var viewerPanel = element.parents("div[id^=komet_viewer_]");

            // if the viewerID was not passed it (but not if it is null), look up what it should be
            if (viewerID === undefined) {

                if (viewerPanel.length > 0) {
                    viewerID = viewerPanel.first().attr("data-komet-viewer-id");
                } else {
                    viewerID = WindowManager.getLinkedViewerID();
                }
            }

            $.publish(KometChannels.Mapping.mappingTreeNodeSelectedChannel, ["", id, viewerID, windowType]);
        };
    }

    function copyConcept(id, conceptText, conceptType){

        return function(){
            conceptClipboard = {id: id, conceptText: conceptText, conceptType: conceptType};
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

    function openConceptEditor(element, id, viewerID, windowType, parentID, parentText, parentType) {

        return function () {

            var viewerPanel = element.parents("div[id^=komet_viewer_]");

            // if the viewerID was not passed it (but not if it is null), look up what it should be
            if (viewerID === undefined) {

                if (viewerPanel.length > 0) {
                    viewerID = viewerPanel.first().attr("data-komet-viewer-id");
                } else {
                    viewerID = WindowManager.getLinkedViewerID();
                }
            }

            $.publish(KometChannels.Taxonomy.taxonomyConceptEditorChannel, [id, viewerID, windowType, {parentID: parentID, parentText: parentText, parentType: parentType}]);
        };
    }

    function cloneConcept(id) {

        return function (){

            params = {id: id} ;

            $.get( gon.routes.taxonomy_clone_concept_path , params, function( results ) {
                console.log("Clone Concept " + uuid);
            });
        };
    }

    function changeConceptState(id, newState) {

        return function (){

            params = {id: id, newState: newState } ;

            $.get( gon.routes.taxonomy_change_concept_state_path , params, function( results ) {
                TaxonomyModule.tree.reloadTreeStatedView($("#komet_taxonomy_stated_inferred")[0].value);
            });
        };
    }

    function pasteConcept(idField, displayField, typeField){

        return function(){

            $("#" + idField).val(conceptClipboard.id);
            $("#" + displayField).val(conceptClipboard.conceptText);
            $("#" + typeField).val(conceptClipboard.conceptType);
        };
    }

    return {
        getActiveTabId: getActiveTabId,
        isTabActive: isTabActive,
        initializeContextMenus: initializeContextMenus,
        generateFormErrorMessage: generateFormErrorMessage,
        generateConfirmationDialog: generateConfirmationDialog,
        toggleChangeHighlights: toggleChangeHighlights,
        toggleFieldAvailability: toggleFieldAvailability,
        hasFormChanged: hasFormChanged,
        resetFormChanges: resetFormChanges,
        acceptFormChanges: acceptFormChanges,
        findInArray: findInArray,
        createAutoSuggestField: createAutoSuggestField,
        processAutoSuggestTags: processAutoSuggestTags,
        loadAutoSuggestRecents: loadAutoSuggestRecents,
        useAutoSuggestRecent: useAutoSuggestRecent,
        getElementRightFromWindow: getElementRightFromWindow,
        VHAT: VHAT,
        SNOMED: SNOMED,
        LOINC: LOINC,
        RXNORM: RXNORM,
        CHANGEABLE_CLASS: CHANGEABLE_CLASS,
        CHANGE_HIGHLIGHT_CLASS: CHANGE_HIGHLIGHT_CLASS
    };
})();


