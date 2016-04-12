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

    function initializeContextMenus() {

        $.contextMenu({
            selector: '.komet-context-menu',
            build: function($triggerElement, e){

                var items = {};

                if ($triggerElement.attr("data-menu-type") === "sememe"){

                    var uuid = $triggerElement.attr("data-menu-uuid");

                    items.openConcept = {name:"Open in Concept Pane", icon: "context-menu-icon glyphicon-list-alt", callback: openConcept(uuid)};
                    items.copyUuid = {name:"Copy UUID", icon: "context-menu-icon glyphicon-copy", callback: copyToClipboard(uuid)};

                } else if ($triggerElement.attr("data-menu-type") === "concept"){

                    var uuid = $triggerElement.attr("data-menu-uuid");

                    items.openConcept = {name:"Open in Concept Pane", icon: "context-menu-icon glyphicon-list-alt", callback: openConcept(uuid)};
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

    function openConcept(id) {

        return function () {
            $.publish(KometChannels.Taxonomy.taxonomyTreeNodeSelectedChannel, id)
        };
    }

    return {
        getActiveTabId: getActiveTabId,
        isTabActive: isTabActive,
        initializeContextMenus: initializeContextMenus
    };
})();


