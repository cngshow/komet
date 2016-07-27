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

                if ($triggerElement.attr("data-menu-type") === "sememe" || $triggerElement.attr("data-menu-type") === "concept"){

                    var uuid = $triggerElement.attr("data-menu-uuid");

                    items.openConcept = {name:"Open in Concept Pane", icon: "context-menu-icon glyphicon-list-alt", callback: openConcept($triggerElement, uuid)};

                    if (WindowManager.viewers.inlineViewers.length < WindowManager.viewers.maxInlineViewers) {
                        items.openNewConceptViwer = {
                            name: "Open in New Concept Viewer",
                            icon: "context-menu-icon glyphicon-list-alt",
                            callback: openConcept($triggerElement, uuid, null, WindowManager.NEW)
                        };
                    }

                    //items.openConceptNewWindow = {name:"Open in New Window", icon: "context-menu-icon glyphicon-list-alt", callback: openConcept($triggerElement, uuid, "popup")};
                    items.copyUuid = {name:"Copy UUID", icon: "context-menu-icon glyphicon-copy", callback: copyToClipboard(uuid)};

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

    function getOpenConceptIcon(opt, $itemElement, itemKey, item) {
        // Set the content to the menu trigger selector and add an bootstrap icon to the item.
        $itemElement.html('<span class="glyphicon glyphicon-star" aria-hidden="true"></span> ' + opt.selector);

        // Add the context-menu-icon-updated class to the item
        return 'context-menu-icon-updated';
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

    function openConcept(element, id, viewerID, windowType) {

        return function () {

            var stated;
            var conceptPanel = element.parents("div[id^=komet_viewer_]");

            if (viewerID === undefined){

                if (conceptPanel.length > 0){
                    viewerID = conceptPanel.first().attr("data-komet-viewer-id");
                } else{
                    viewerID = WindowManager.getLinkedViewerID();
                }
            }

            if (conceptPanel.length > 0){
                stated = WindowManager.viewers[viewerID].getStatedView();
            } else{
                stated = TaxonomyModule.getStatedView();
            }

            $.publish(KometChannels.Taxonomy.taxonomyTreeNodeSelectedChannel, ["", id, stated, viewerID, windowType]);
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

    return {
        getActiveTabId: getActiveTabId,
        isTabActive: isTabActive,
        initializeContextMenus: initializeContextMenus,
        generateFormErrorMessage: generateFormErrorMessage,
        toggleFieldAvailability: toggleFieldAvailability
    };
})();


