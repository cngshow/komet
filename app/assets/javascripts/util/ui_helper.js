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
    var autoSuggestRecentCache = {};
    var deferredRecentsCalls = null;
    const VHAT = "vhat";
    const SNOMED = "snomed";
    const LOINC = "loinc";
    const RXNORM = "rxnorm";
    const CHANGEABLE_CLASS = "komet-changeable";
    const CHANGE_HIGHLIGHT_CLASS = "komet-highlight-changes";
    const RECENTS_ASSOCIATION = 'association';
    const RECENTS_MAPSET = 'mapset';
    const RECENTS_SEMEME = 'sememe';
    const RECENTS_METADATA = 'metadata';

    /*
     * initDatePicker - Initialize a date picker input group to with a starting date
     * @param [object or string] elementOrSelector - Either a jquery object or the class or ID selector (including the "#" or "." prefix) that represents the date picker input group we are initializing.
     * @param [Number or string] startingDate - a long number that represents the date in milliseconds since the epoch, or the string 'latest'
     * @param [function] onChangeFunction - a function object that will be run when the date is changed (takes an event parameter which includes .oldDate and .date (the new date)
     */
    function initDatePicker(elementOrSelector, startingDate, onChangeFunction) {

        var datePicker;

        // If the type of the first parameter is a string, then use it as a jquery selector, otherwise use as is
        if (typeof elementOrSelector === "string") {
            datePicker = $(elementOrSelector);
        } else {
            datePicker = elementOrSelector;
        }

        // get the date field input field
        var input_field = datePicker.find("input");

        // set the params for the date field
        var date_params = {
            useCurrent: false,
            showClear: true,
            showTodayButton: true,
            icons: {
                time: "fa fa-clock-o",
                date: "fa fa-calendar",
                up: "fa fa-arrow-up",
                down: "fa fa-arrow-down"
            }
        };

        // if the starting date is not 'latest' then set the default date param to the starting value. The plus is in case the value is a string
        if (startingDate != null && startingDate != undefined && startingDate != 'latest'){
            date_params.defaultDate = moment(+startingDate);
        }

        // create the date field
        input_field.datetimepicker(date_params);

        // If it was passed in, set the field onChange function to the passed in function
        if (onChangeFunction != null && onChangeFunction != undefined){
            input_field.on("dp.change", onChangeFunction);
        }
    }

    /*
     * setStampDate - set the value of a Stated field radio button group
     * @param [object or string] elementOrSelector - Either a jquery object or the class or ID selector (including the "#" or "." prefix) that represents the date picker input group whose value we are setting.
     * @param [string] newValue - the value to set the value of the field to
     */
    function setStampDate(elementOrSelector, newValue) {

        var dateGroup;

        // If the type of the first parameter is a string, then use it as a jquery selector, otherwise use as is
        if (typeof elementOrSelector === "string") {
            dateGroup = $(elementOrSelector);
        } else {
            dateGroup = elementOrSelector;
        }

        if (newValue == 'latest'){
            newValue = '';
        }

        // set the date input value
        dateGroup.find("input").val(newValue);
    }

    // function to the the position of an element from the edge of the viewpoint
    function getOffset(element) {

        element = element.getBoundingClientRect();

        return {
            left: element.left + window.scrollX,
            top: element.top + window.scrollY
        }
    }

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

    function generatePageMessage(message, isPageLevelMessage, messageType) {

        if (messageType == undefined || messageType == null || !(messageType == "success" || messageType == "warning")) {
            messageType = "error";
        }

        var icon = '<div class="glyphicon glyphicon-alert" title="alert message"></div>';

        if (messageType == "success") {
            icon = '<div class="glyphicon glyphicon-ok-circle" title="success message"></div>';
        }

        var messageType = "komet-page-" + messageType;
        var classLevel = "komet-page-field-message";

        if (isPageLevelMessage != undefined && isPageLevelMessage) {
            classLevel = "komet-page-message";
        }

        var id = window.performance.now().toString().replace(".", "");

        return '<div id="komet_' + id + '" class="' + classLevel + ' ' + messageType + '">' + icon + '<div class="komet-page-message-container" role="alert">' + message + '</div>'
            + '<div class="komet-flex-right"><button type="button" class="komet-link-button" title="Remove message" aria-label="Remove alert: ' + message + '" onclick="$(\'#komet_' + id + '\').remove();"><div class="glyphicon glyphicon-remove"  ></div></button></div></div>';
    }

    function removePageMessages(containerElementOrSelector) {

        var element;

        // If the type of the first parameter is a string, then use it as a jquery selector, otherwise use as is
        if (typeof containerElementOrSelector === "string") {
            element = $(containerElementOrSelector);
        } else {
            element = containerElementOrSelector;
        }

        element.find(".komet-page-message, .komet-page-field-message").remove();
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

        if (formID == undefined) {
            formID = null;
        } else {
            buttonType = "submit";
        }

        body.prepend(dialogString);

        // create a function to put focus on the first input field
        var onDialogOpen = function(){
            $("#" + dialogID).find("input:not(.hide):first").focus();
        };

        var dialog = $("#" + dialogID);

        dialog.dialog({
            beforeClose: function () {

                closeCallback(buttonClicked);
                dialog.remove();
            },
            open: function () {

                // use setTimeout because the first field could be an autosuggest that needs to get built first.
                setTimeout(onDialogOpen, 50);
            },
            title: title,
            resizable: false,
            height: "auto",
            width: 500,
            modal: true,
            position: position,
            dialogClass: "komet-confirmation-dialog komet-dialog-no-close-button",
            buttons: {
                Cancel: {
                    "class": "btn btn-default",
                    text: "Cancel",
                    click: function () {
                        $(this).dialog("close");
                    }
                },
                OK: {
                    text: buttonText,
                    "class": "btn btn-primary",
                    click: function () {

                        buttonClicked = buttonText;
                        $(this).dialog("close");
                    },
                    type: buttonType,
                    form: formID
                }
            }
        });

        dialog.parent().children().children(".ui-dialog-titlebar-close").remove();
    }

    // TODO - Not very useful if showChanges is true
    function toggleChangeHighlights(containerElementOrSelector, showChanges) {

        var element;

        // If the type of the first parameter is a string, then use it as a jquery selector, otherwise use as is
        if (typeof containerElementOrSelector === "string") {
            element = $(containerElementOrSelector);
        } else {
            element = containerElementOrSelector;
        }

        var tags = element.find(".komet-changeable");

        if (showChanges) {
            tags.addClass("komet-highlight-changes");
        } else {
            tags.removeClass("komet-highlight-changes");
        }
    }

    // function to switch a field between enabled and disabled
    function toggleFieldAvailability(elementOrSelector, enable) {

        var element;

        // If the type of the first parameter is a string, then use it as a jquery selector, otherwise use as is
        if (typeof elementOrSelector === "string") {
            element = $(elementOrSelector);
        } else {
            element = elementOrSelector;
        }

        if (enable) {

            element.removeClass("ui-state-disabled");
            element.prop("disabled", false);
        } else {

            element.addClass("ui-state-disabled");
            element.prop("disabled", true);
        }
    }

    /*
     * hasFormChanged - Check to see if there were changes in a form, optionally returning the change details and highlighting them.
     * @param [object or string] formElementOrSelector - Either a jquery object or the class or ID selector (including the "#" or "." prefix) that represents the form to search for changes.
     * @param [boolean] returnChanges - Should an array of changes be returned (true), or simply true/false (false). If this and highlightChanges
     *                                  are false then the function will only loop until it finds the first change. (Optional: default = false)
     * @param [boolean] highlightChanges - Should changes be highlighted. Requires the "komet-changeable" class on the elements you want highlighted. (Optional: default = false)
     * @return [array or boolean] - If returnChanges is true, returns an array containing a hash of each fields changes ({field, oldValue, newValue}), otherwise returns true or false.
     */
    function hasFormChanged(formElementOrSelector, returnChanges, highlightChanges) {

        var changes = [];
        var element;

        // set the default value if this optional parameter wasn't passed in
        if (returnChanges == undefined) {
            returnChanges = false;
        }

        // set the default value if this optional parameter wasn't passed in
        if (highlightChanges == undefined) {
            highlightChanges = false;
        }

        // If the type of the first parameter is a string, then use it as a jquery selector, otherwise use as is
        if (typeof formElementOrSelector === "string") {
            element = $(formElementOrSelector);
        } else {
            element = formElementOrSelector;
        }

        // remove current highlights
        UIHelper.toggleChangeHighlights(element, false);

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
                        if (this.type == "select-one") {

                            // if the old selected value was true then this is the old value, otherwise it's the new value
                            if (this.options[i].defaultSelected) {
                                field.oldValue = this.options[i].value;
                            } else {

                                field.newValue = this.options[i].value;

                                // if the old value is still an empty array, set it to an empty string, because it may have never had a value selected
                                if (typeof field.oldValue == "object") {
                                    field.oldValue = "";
                                }
                            }

                        } else {

                            // if this is a multi selection select box then we need to store values as an array
                            // if the old selected value was true then this is the old value, otherwise it's the new value
                            if (this.options[i].defaultSelected) {
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
                if (!returnChanges && !highlightChanges) {
                    changes.push(field);
                    return false;
                }

                // add the field to the changes array
                changes.push(field);

                // if we are highlighting changes then find the nearest element with the changeable class, and add the hightlight class
                if (highlightChanges) {
                    $(this).closest(".komet-changeable").addClass("komet-highlight-changes");
                }
            }
        });

        // if we are not returning the array of changes then check to see if there were changes
        if (!returnChanges) {

            if (changes.length > 0) {
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
        if (typeof formElementOrSelector === "string") {
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

    var createAutoSuggestField = function (fieldIDBase, fieldIDPostfix, label, labelDisplay, name, nameFormat, idValue, displayValue, typeValue, fieldClasses, tabIndex) {

        if (fieldIDPostfix == null) {
            fieldIDPostfix = "";
        }

        var labelTag = "";
        var caption = "";

        if (label != null) {

            caption = ' aria-label="' + label + '" ';

            if (labelDisplay == null || labelDisplay == 'label') {
                labelTag = '<label for="' + fieldIDBase + '_display' + fieldIDPostfix + '">' + label + '</label>';

            } else if (labelDisplay == 'tooltip') {
                caption += 'title="' + label + '" ';

            } else {
                caption += 'placeholder="' + label + '" ';
            }

        }

        var idName = fieldIDBase;
        var typeName = fieldIDBase + "_type";
        var displayName = fieldIDBase + "_display";

        if (name != null) {

            if (nameFormat == "array") {

                idName = name + "]";
                typeName = name + "_type]";
                displayName = name + "_display]";

            } else {

                idName = name;
                typeName = name + "_type";
                displayName = name + "_display";
            }
        }

        if (idValue == null) {
            idValue = "";
        }

        if (displayValue == null) {
            displayValue = "";
        }

        if (typeValue == null) {
            typeValue = "";
        }

        if (fieldClasses == null) {
            fieldClasses = "";
        }

        var fieldTabIndex = ""
        var recentsTabIndex = ""

        if (tabIndex != null) {

            fieldTabIndex = ' tabindex="' + tabIndex + '"';
            recentsTabIndex = ' tabindex="' + (tabIndex + 1) + '"';
        }

        // use the hide class to hide the ID and Type fields so that the hasFormChanged() function can pick up the changed values.
        // add type=hidden to inputs with class=hidden.
        var fieldString = labelTag
            + '<input type="hidden" id="' + fieldIDBase + fieldIDPostfix + '" name="' + idName + '" class="hide" value="' + idValue + '">'
            + '<input type="hidden" id="' + fieldIDBase + '_type' + fieldIDPostfix + '" name="' + typeName + '" class="hide" value="' + typeValue + '">'
            + '<div id="' + fieldIDBase + '_fields' + fieldIDPostfix + '" class="komet-autosuggest input-group ' + fieldClasses + '">'
            + '<input id="' + fieldIDBase + '_display' + fieldIDPostfix + '" name="' + displayName + '" ' + caption + ' class="form-control komet-context-menu" '
            + 'data-menu-type="paste_target" data-menu-id-field="' + fieldIDBase + fieldIDPostfix + '" data-menu-display-field="' + fieldIDBase + '_display' + fieldIDPostfix + '" '
            + 'data-menu-taxonomy-type-field="' + fieldIDBase + '_type' + fieldIDPostfix + '" value="' + displayValue + '"' + fieldTabIndex + '>'
            + '<div id="' + fieldIDBase + '_recents_button' + fieldIDPostfix + '"  class="input-group-btn komet-search-combo-field">'
            + '<button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-label="Select ' + displayName + '" aria-haspopup="true" aria-expanded="false"><span class="caret"></span></button>'
            + '<ul id="' + fieldIDBase + '_recents' + fieldIDPostfix + '" class="dropdown-menu dropdown-menu-right"' + recentsTabIndex + '></ul>'
            + '</div></div>';

        // create and return a dom fragment from the field string
        return document.createRange().createContextualFragment(fieldString);
    };

    var processAutoSuggestTags = function (containerElementOrSelector) {

        var element;

        // If the type of the first parameter is a string, then use it as a jquery selector, otherwise use as is
        if (typeof containerElementOrSelector === "string") {
            element = $(containerElementOrSelector);
        } else {
            element = containerElementOrSelector;
        }

        var tags = $(element).find("autosuggest");

        tags.each(function (i, tag) {

            var fieldIDBase = tag.getAttribute("id-base");
            var fieldIDPostfix = tag.getAttribute("id-postfix");
            var label = tag.getAttribute("label");
            var labelDisplay = tag.getAttribute("label-display");
            var name = tag.getAttribute("name");
            var nameFormat = tag.getAttribute("name-format");
            var idValue = tag.getAttribute("value");
            var displayValue = tag.getAttribute("display-value");
            var typeValue = tag.getAttribute("type-value");
            var fieldClasses = tag.getAttribute("classes");
            var tabIndex = tag.getAttribute("tab-index");
            var suggestionRestVariable = tag.getAttribute("suggestion-rest-variable");
            var recentsRestVariable = tag.getAttribute("recents-rest-variable");
            var useRecentsCache = tag.getAttribute("use-recents-cache");
            var characterTriggerLimit = tag.getAttribute("character-trigger-limit");
            var restrictSearch = tag.getAttribute("restrict-search");
            var viewParams = tag.getAttribute("view_params");

            if (fieldIDPostfix == null) {
                fieldIDPostfix = "";
            }

            if (suggestionRestVariable == null) {
                suggestionRestVariable = "komet_dashboard_get_concept_suggestions_path";
            }

            if (characterTriggerLimit == null) {
                characterTriggerLimit = 1;
            }

            if (restrictSearch == null) {
                restrictSearch = "";
            }

            var autoSuggest = UIHelper.createAutoSuggestField(fieldIDBase, fieldIDPostfix, label, labelDisplay, name, nameFormat, idValue, displayValue, typeValue, fieldClasses, tabIndex);

            $(tag).replaceWith(autoSuggest);

            var displayField = $("#" + fieldIDBase + "_display" + fieldIDPostfix);

            displayField.autocomplete({
                source: gon.routes[suggestionRestVariable] + '?restrict_search=' + restrictSearch + '&' + jQuery.param({view_params: viewParams}),
                minLength: characterTriggerLimit,
                select: onAutoSuggestSelection
                , change: onAutoSuggestChange(characterTriggerLimit)
            });

            displayField.data("ui-autocomplete")._renderItem = function (ul, item) {

                var matchingText = "";

                if (item.label != item.matching_text){
                    matchingText = " (Matching Text: " + item.matching_text + ")";
                }

                var li = $('<li class="ui-menu-item">' + item.label + matchingText + '</li>').data('ui-autocomplete-item', item);
                return ul.append(li);
            };

            var recentsButton = $("#" + fieldIDBase + "_recents_button" + fieldIDPostfix);

            recentsButton.on('show.bs.dropdown', function () {

                var menu = $("#" + fieldIDBase + "_recents" + fieldIDPostfix);
                menu.css("position", "fixed");
                menu.css("top", recentsButton.offset().top + recentsButton.height());
                menu.css("right", getElementRightFromWindow(recentsButton));
            }.bind(this));

            var thisHelper = this;

            recentsDropdown = $("#" + fieldIDBase + "_recents" + fieldIDPostfix);

            // TODO - Switch to using this event so we can trigger menu reloading easily
            recentsDropdown.on("recents:load", {restVariable: recentsRestVariable, useRecentsCache: useRecentsCache, recentsName: restrictSearch}, function(event) {

                if (event.data.useRecentsCache == null){
                    event.data.useRecentsCache = true;
                }

                // use the recents cache if it exists
                if (event.data.useRecentsCache && thisHelper.autoSuggestRecentCache[event.data.recentsName] != null){

                    $(this).html(thisHelper.autoSuggestRecentCache[event.data.recentsName]);
                    return;
                }

                if (event.data.restVariable == null) {
                    event.data.restVariable = "komet_dashboard_get_concept_recents_path";
                }

                $.get(gon.routes[event.data.restVariable] + '?recents_name=' + event.data.recentsName, function (data) {

                    var options = "";

                    $.each(data, function (index, value) {

                        var autoSuggestIDField = this.id.replace("_recents", "");
                        var autoSuggestDisplayField = this.id.replace("_recents", "_display");
                        var autoSuggestTypeField = this.id.replace("_recents", "_type");

                        // use the html function to escape any html that may have been entered by the user
                        var valueText = $("<li>").text(value.text).html();

                        // TODO - remove this reassignment when the type flags are implemented in the REST APIs
                        value.type = UIHelper.VHAT;

                        options += '<li><a style="cursor: default"  onclick=\'UIHelper.useAutoSuggestRecent("' + autoSuggestIDField + '", "' + autoSuggestDisplayField + '", "' + autoSuggestTypeField + '"'
                            + ', "' + value.id + '", "' + valueText + '", "' + value.type + '")\'>' + valueText + '</a></li>';
                    }.bind(this));

                    $(this).html(options);

                    if (event.data.useRecentsCache) {
                        thisHelper.autoSuggestRecentCache[event.data.recentsName] = options;
                    }

                }.bind(this));
            });

            // recentsDropdown.trigger("recents:load");

            if (deferredRecentsCalls && deferredRecentsCalls.state() == "pending"){

                deferredRecentsCalls.done(function(){
                    loadAutoSuggestRecents(fieldIDBase + "_recents" + fieldIDPostfix, recentsRestVariable, useRecentsCache, restrictSearch);
                }.bind(this));

            } else {
                loadAutoSuggestRecents(fieldIDBase + "_recents" + fieldIDPostfix, recentsRestVariable, useRecentsCache, restrictSearch);
            }
        });
    };

    var onAutoSuggestSelection = function (event, ui) {

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

    var onAutoSuggestChange = function (characterTriggerLimit) {

        return function (event, ui) {

            if (this.value.length == 0 || (this.value.length >= characterTriggerLimit && !ui.item)) {

                var idField = $("#" + this.id.replace("_display", ""));
                idField.val("");
                idField.change();

                var typeField = $("#" + this.id.replace("_display", "_type"));
                typeField.val("");
                typeField.change();

                // make sure this is last, as there may be an onchange event on the display field that requires the other fields to be set.
                var labelField = $(this);
                labelField.val("");
                labelField.change();
            }
        };
    };

    var loadAutoSuggestRecents = function (recentsID, restVariable, useRecentsCache, recentsName) {

        deferredRecentsCalls = $.Deferred();

        if (useRecentsCache == null){
            useRecentsCache = true;
        }

        // use the recents cache if it exists
        if (useRecentsCache && autoSuggestRecentCache[recentsName] != null){

            $("#" + recentsID).html(autoSuggestRecentCache[recentsName]);
            deferredRecentsCalls.resolve();
            return;
        }

        if (restVariable == null) {
            restVariable = "komet_dashboard_get_concept_recents_path";
        }

        $.get(gon.routes[restVariable] + '?recents_name=' + recentsName, function (data) {

            var options = "";

            $.each(data, function (index, value) {

                var autoSuggestIDField = recentsID.replace("_recents", "");
                var autoSuggestDisplayField = recentsID.replace("_recents", "_display");
                var autoSuggestTypeField = recentsID.replace("_recents", "_type");

                // use the html function to escape any html that may have been entered by the user
                var valueText = $("<li>").text(value.text).html();

                // TODO - remove this reassignment when the type flags are implemented in the REST APIs
                value.type = UIHelper.VHAT;

                options += '<li><a style="cursor: default"  onclick=\'UIHelper.useAutoSuggestRecent("' + autoSuggestIDField + '", "' + autoSuggestDisplayField + '", "' + autoSuggestTypeField + '"'
                    + ', "' + value.id + '", "' + valueText + '", "' + value.type + '")\'>' + valueText + '</a></li>';
            });

            $("#" + recentsID).html(options);

            if (useRecentsCache) {

                autoSuggestRecentCache[recentsName] = options;
                deferredRecentsCalls.resolve();
            }

        });
    };

    var clearAutoSuggestRecentCache = function (name){

        if (name == undefined || name == null){
            autoSuggestRecentCache = {};
        } else {
            delete autoSuggestRecentCache[name];
        }
    };

    var useAutoSuggestRecent = function (autoSuggestID, autoSuggestDisplayField, autoSuggestTypeField, id, text, type) {

        var idField = $("#" + autoSuggestID);
        idField.val(id);
        idField.change();

        var typeField = $("#" + autoSuggestTypeField);
        typeField.val(type);
        typeField.change();

        // make sure this is last, as there may be an onchange event on the display field that requires the other fields to be set.
        var displayField = $("#" + autoSuggestDisplayField);
        displayField.val(text);
        displayField.change();

    };

    var createSelectFieldString = function(selectID, selectName, classes, options, selectedItem, label, createEmptyOption, displayOptionTooltips) {

        if (createEmptyOption == null || createEmptyOption == undefined){
            createEmptyOption = false;
        }

        if (displayOptionTooltips == null || displayOptionTooltips == undefined){
            displayOptionTooltips = false;
        }

        var fieldString = '<select id="' + selectID + '"'
            + ' name="' + selectName + '"'
            + ' class="form-control ' + classes + '"'
            + ((label) ? (' aria-label="' + label) + '"' : '')
            + '>';

        // create an empty option tag if that was specified
        if (createEmptyOption){

            fieldString += '<option ';

            // make sure to select it if there was no value for the field, otherwise the dirty form check will get triggered
            if (selectedItem == null || selectedItem.toString() == "") {
                fieldString += 'selected="selected" ';
            }

            fieldString += 'value=""></option>';
        }

        for (var i = 0; i < options.length; i++) {

            fieldString += '<option ';

            if (displayOptionTooltips){
                fieldString += 'title="' + options[i].tooltip + '" ';
            }

            if (selectedItem != null && selectedItem.toString().toLowerCase() == options[i].value.toString().toLowerCase()) {
                fieldString += 'selected="selected" ';
            }

            fieldString += 'value="' + options[i].value + '">' + options[i].label + '</option>';
        }

        fieldString += '</select>';

        return fieldString;
    };

    var getPreDefinedOptionsForSelect = function(type){

        if (type == "yes_no"){
            return [{value: "yes", label: "Yes"}, {value: "no", label: "No"}];
        } else if (type == "true_false") {
            return [{value: "true", label: "True"}, {value: "false", label: "False"}];
        } else if (type == "active_inactive") {
            return [{value: "active", label: "Active"}, {value: "inactive", label: "Inactive"}];
        }
    };

    var getElementRightFromWindow = function(elementOrSelector){

        var element;

        // If the type of the first parameter is a string, then use it as a jquery selector, otherwise use as is
        if (typeof elementOrSelector === "string") {
            element = $(elementOrSelector);
        } else {
            element = elementOrSelector;
        }

        if (element.length > 0) {
            return ($(window).width() - (element.offset().left + element.outerWidth()));
        } else {
            return null;
        }
    };

    // TODO - Fix z-index of menus in IE - splitter bars cutting through it
    function initializeContextMenus() {

        $.contextMenu({
            selector: '.komet-context-menu',
            events: {
                show: function (opt) {
                    // show event is executed every time the menu is shown!
                    // find all clickable commands and set their title-attribute
                    // to their textContent value
                    opt.$menu.find('.context-menu-item > span').attr('title', function () {
                        return $(this).text();
                    });
                }
            },
            build: function ($triggerElement, e) {

                var items = {};
                var menuType = $triggerElement.attr("data-menu-type");

                if (menuType == "sememe" || menuType == "concept" || menuType == "map_set") {

                    var uuid = $triggerElement.attr("data-menu-uuid");
                    var conceptText = $triggerElement.attr("data-menu-concept-text");
                    var conceptTerminologyType = $triggerElement.attr("data-menu-concept-terminology-type");
                    var conceptState = $triggerElement.attr("data-menu-state");
                    var unlinkedViewerID = WindowManager.getUnlinkedViewerID();

                    if (conceptText == undefined || conceptText == "") {
                        conceptText = null;
                    }

                    if (conceptState == undefined || conceptState == "") {
                        conceptState = null;
                    }

                    if (conceptTerminologyType == undefined || conceptTerminologyType == "") {
                        conceptTerminologyType = null;
                    }

                    items.openConcept = {
                        name: "Open Concept",
                        icon: "context-menu-icon glyphicon-list-alt",
                        callback: openConcept($triggerElement, uuid)
                    };

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

                    if (menuType == "map_set") {

                        items.separatorMapping = {type: "cm_separator"};

                        items.openMapSet = {
                            name: "Open Mapping",
                            icon: "context-menu-icon glyphicon-list-alt",
                            callback: openMapSet($triggerElement, uuid)
                        };

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
                        items.copyConcept = {
                            name: "Copy Concept",
                            icon: "context-menu-icon glyphicon-copy",
                            callback: copyConcept(uuid, conceptText, conceptTerminologyType)
                        };
                    }

                    items.copyUuid = {
                        name: "Copy UUID",
                        icon: "context-menu-icon glyphicon-copy",
                        callback: copyToClipboard(uuid)
                    };

                    // check the dynaimc role methods to see if the user can edit concepts
                    if (RolesModule.can_edit_concept()) {

                        items.separatorConceptEditor = {type: "cm_separator"};

                        items.editConcept = {
                            name: "Edit Concept",
                            icon: "context-menu-icon glyphicon-pencil",
                            callback: openConceptEditor($triggerElement, ConceptsModule.EDIT, uuid)
                        };

                        if (WindowManager.viewers.inlineViewers.length < WindowManager.viewers.maxInlineViewers) {

                            items.editConceptNewViewer = {
                                name: "Edit Concept in New Viewer",
                                icon: "context-menu-icon glyphicon-pencil",
                                callback: openConceptEditor($triggerElement, ConceptsModule.EDIT, uuid, WindowManager.NEW, WindowManager.NEW)
                            };
                        }

                        if (WindowManager.viewers.inlineViewers.length > 1) {

                            items.editConceptUnlinkedViewer = {
                                name: "Edit Concept in Unlinked Viewer",
                                icon: "context-menu-icon glyphicon-pencil",
                                callback: openConceptEditor($triggerElement, ConceptsModule.EDIT, uuid, unlinkedViewerID)
                            };
                        }

                        items.cloneConcept = {
                            name: "Clone Concept",
                            icon: "context-menu-icon glyphicon-share",
                            callback: openConceptEditor($triggerElement, ConceptsModule.CLONE, uuid)
                        };

                        if (WindowManager.viewers.inlineViewers.length < WindowManager.viewers.maxInlineViewers) {

                            items.cloneConceptNewViewer = {
                                name: "Clone Concept in New Viewer",
                                icon: "context-menu-icon glyphicon-share",
                                callback: openConceptEditor($triggerElement, ConceptsModule.CLONE, uuid, WindowManager.NEW, WindowManager.NEW)
                            };
                        }

                        if (WindowManager.viewers.inlineViewers.length > 1) {

                            items.cloneConceptUnlinkedViewer = {
                                name: "Clone Concept in Unlinked Viewer",
                                icon: "context-menu-icon glyphicon-share",
                                callback: openConceptEditor($triggerElement, ConceptsModule.CLONE, uuid, unlinkedViewerID)
                            };
                        }

                        if (conceptText != null && conceptTerminologyType != null) {

                            items.createChildConcept = {
                                name: "Create Child Concept",
                                icon: "context-menu-icon glyphicon-plus",
                                callback: openConceptEditor($triggerElement, ConceptsModule.CREATE, null, WindowManager.getLinkedViewerID(), WindowManager.INLINE, uuid, conceptText, conceptTerminologyType)
                            };

                            if (WindowManager.viewers.inlineViewers.length < WindowManager.viewers.maxInlineViewers) {

                                items.createChildConceptNewViewer = {
                                    name: "Create Child Concept in New Viewer",
                                    icon: "context-menu-icon glyphicon-plus",
                                    callback: openConceptEditor($triggerElement, ConceptsModule.CREATE, null, WindowManager.NEW, WindowManager.NEW, uuid, conceptText, conceptTerminologyType)
                                };
                            }

                            if (WindowManager.viewers.inlineViewers.length > 1) {

                                items.createChildConceptUnlinkedViewer = {
                                    name: "Create Child Concept in Unlinked Viewer",
                                    icon: "context-menu-icon glyphicon-plus",
                                    callback: openConceptEditor($triggerElement, ConceptsModule.CREATE, null, unlinkedViewerID, WindowManager.INLINE, uuid, conceptText, conceptTerminologyType)
                                };
                            }
                        }

                        if (conceptState != null) {

                            items.separatorState = {type: "cm_separator"};

                            if (conceptState.toLowerCase() == 'active') {
                                items.activeInactiveUuid = {
                                    name: "Inactivate Concept",
                                    icon: "context-menu-icon glyphicon-ban-circle",
                                    callback: changeConceptState($triggerElement, uuid, conceptText, 'false')
                                };
                            } else {
                                items.activeInactiveUuid = {
                                    name: "Activate Concept",
                                    icon: "context-menu-icon glyphicon-ok-circle",
                                    callback: changeConceptState($triggerElement, uuid, conceptText, 'true')
                                };
                            }
                        }
                    }
                } else if (menuType == "paste_target") {

                    var idField = $triggerElement.attr("data-menu-id-field");
                    var displayField = $triggerElement.attr("data-menu-display-field");
                    var typeField = $triggerElement.attr("data-menu-taxonomy-type-field");

                    if (conceptClipboard.id != undefined) {
                        items.pasteConcept = {
                            name: "Paste Concept: " + conceptClipboard.conceptText,
                            isHtmlName: true,
                            icon: "context-menu-icon glyphicon-paste",
                            callback: pasteConcept(idField, displayField, typeField)
                        }
                    }

                } else {
                    items.copy = {
                        name: "Copy",
                        icon: "context-menu-icon glyphicon-copy",
                        callback: copyToClipboard($triggerElement.attr("data-menu-copy-value"))
                    };
                }

                return {
                    callback: function () {
                    },
                    items: items
                };
            }
        });
    }

    // Context menu functions

    function openConcept(element, id, viewerID, windowType) {

        return function () {

            var viewerPanel = element.parents("div[id^=komet_viewer_]");
            var viewParams;

            // if the viewerID was not passed it (but not if it is null), look up what it should be
            if (viewerID === undefined) {

                if (viewerPanel.length > 0) {
                    viewerID = viewerPanel.first().attr("data-komet-viewer-id");
                } else {
                    viewerID = WindowManager.getLinkedViewerID();
                }
            }

            if (viewerPanel.length > 0) {
                viewParams = WindowManager.viewers[viewerID].getViewParams();
            } else {
                viewParams = TaxonomyModule.getViewParams();
            }

            $.publish(KometChannels.Taxonomy.taxonomyTreeNodeSelectedChannel, ["", id, viewParams, viewerID, windowType]);
        };
    }

    function openMapSet(element, id, viewerID, windowType) {

        return function () {

            var viewerPanel = element.parents("div[id^=komet_viewer_]");
            var viewParams;

            // if the viewerID was not passed it (but not if it is null), look up what it should be
            if (viewerID === undefined) {

                if (viewerPanel.length > 0) {

                    viewerID = viewerPanel.first().attr("data-komet-viewer-id");
                    viewParams = WindowManager.viewers[viewerID].getViewParams();
                } else {

                    viewerID = WindowManager.getLinkedViewerID();
                    viewParams =  MappingModule.getTreeViewParams();
                }
            }

            $.publish(KometChannels.Mapping.mappingTreeNodeSelectedChannel, ["", id, viewParams, viewerID, windowType]);
        };
    }

    function copyConcept(id, conceptText, conceptType) {

        return function () {
            conceptClipboard = {id: id, conceptText: conceptText, conceptType: conceptType};
        };
    }

    function copyToClipboard(text) {

        return function () {
            // have to create a fake element with the value on the page to get copy to work
            var textArea = document.createElement('textarea');
            textArea.setAttribute('style', 'width:1px;border:0;opacity:0;');
            document.body.appendChild(textArea);
            textArea.value = text;
            textArea.select();
            document.execCommand('copy');
            document.body.removeChild(textArea);
        };
    }

    function openConceptEditor(element, action, id, viewerID, windowType, parentID, parentText, parentType) {

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

            $.publish(KometChannels.Taxonomy.taxonomyConceptEditorChannel, [action, id, viewerID, windowType, {
                parentID: parentID,
                parentText: parentText,
                parentType: parentType
            }]);
        };
    }

    function changeConceptState(element, concept_id, conceptText, newState) {

        return function (){

            var params = {concept_id: concept_id, newState: newState } ;

            $.get( gon.routes.taxonomy_change_concept_state_path , params, function( results ) {

                var splitter = $("#komet_west_pane");

                UIHelper.removePageMessages(splitter);

                if (conceptText == null){
                    conceptText = "";
                } else {
                    conceptText = " '" + conceptText + "'";
                }

                if (results.state != null) {

                    splitter.prepend(UIHelper.generatePageMessage("The state of concept " + conceptText + " was successfully updated.", true, "success"));
                    TaxonomyModule.tree.reloadTree(TaxonomyModule.getViewParams(), false);

                    // if the mapping module has been loaded then refresh the mapping tree
                    if (MappingModule.tree){
                        MappingModule.tree.reloadTree(MappingModule.getTreeViewParams());
                    }

                } else {

                    splitter.prepend(UIHelper.generatePageMessage("The concept state was not updated."));
                }
            });
        };
    }

    function pasteConcept(idField, displayField, typeField) {

        return function () {

            $("#" + idField).val(conceptClipboard.id);
            $("#" + displayField).val(conceptClipboard.conceptText);
            $("#" + typeField).val(conceptClipboard.conceptType);
        };
    }

    return {
        initDatePicker: initDatePicker,
        setStampDate: setStampDate,
        getOffset: getOffset,
        getActiveTabId: getActiveTabId,
        isTabActive: isTabActive,
        initializeContextMenus: initializeContextMenus,
        generatePageMessage: generatePageMessage,
        removePageMessages: removePageMessages,
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
        clearAutoSuggestRecentCache: clearAutoSuggestRecentCache,
        createSelectFieldString: createSelectFieldString,
        getPreDefinedOptionsForSelect: getPreDefinedOptionsForSelect,
        getElementRightFromWindow: getElementRightFromWindow,
        VHAT: VHAT,
        SNOMED: SNOMED,
        LOINC: LOINC,
        RXNORM: RXNORM,
        CHANGEABLE_CLASS: CHANGEABLE_CLASS,
        CHANGE_HIGHLIGHT_CLASS: CHANGE_HIGHLIGHT_CLASS,
        RECENTS_ASSOCIATION: RECENTS_ASSOCIATION,
        RECENTS_MAPSET: RECENTS_MAPSET,
        RECENTS_SEMEME: RECENTS_SEMEME,
        RECENTS_METADATA: RECENTS_METADATA
    };
})();


