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
    var open = false;

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

    function togglePanelDetails(panel_id, callback, preserveState) {
        // toggle the visibility of the panel's detail drawer
        $("#" + panel_id + " .komet-concept-section-panel-details").toggle();

        var expander = $("#" + panel_id + " .glyphicon-plus-sign, #" + panel_id + " .glyphicon-minus-sign");

        // change the displayed expander icon
        if (expander.hasClass("glyphicon-plus-sign")) {

            expander.removeClass("glyphicon-plus-sign");
            expander.addClass("glyphicon-minus-sign");
            open = true;

        } else {

            expander.removeClass("glyphicon-minus-sign");
            expander.addClass("glyphicon-plus-sign");
            open = false;
        }

        // if the user clicked on the top level concept expander, change the associated text label
        if (expander.parent().hasClass('komet-concept-body-tools')) {

            var item_text = expander[0].nextElementSibling;

            if (item_text.innerHTML == "Expand All") {
                item_text.innerHTML = "Collapse All";
                open = true;
            } else {
                item_text.innerHTML = "Expand All";
                open = false;
            }
        }
        if (callback && open) {
            callback();
        }
        if (preserveState) {
            var currentState = ConceptsModule.getPanelState(panel_id);
            ConceptsModule.setPanelState(panel_id, open, callback);
        }
    }

    return {
        getActiveTabId: getActiveTabId,
        isTabActive: isTabActive,
        togglePanelDetails: togglePanelDetails
    };
})();


