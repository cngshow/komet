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
 * All Channel strings must be unique even across namespaces!
 * Thus if KometChannels.Taxonomy has:
 * taxonomyTreeNodeOpenedChannel: "Taxonomy/TaxonomyTree/NodeOpened"
 * the value string cannot be used again!!
 */
var KometChannels = {

    Taxonomy: {
        //These strings must be unique across  all channels
        taxonomyTreeNodeOpenedChannel: "Taxonomy/TaxonomyTree/NodeOpened",
        taxonomyTreeNodeClosedChannel: "Taxonomy/TaxonomyTree/NodeClosed",
        taxonomyTreeNodeSelectedChannel: "Taxonomy/TaxonomyTree/NodeSelected",
        taxonomyDetailsTreeNodeSelectedChannel: "Taxonomy/TaxonomyDetailsTree/NodeSelected",
        taxonomySearchResultSelectedChannel: "Taxonomy/Search/ResultSelected"
    },
    //whoever adds in another real namespace can whack this silly example
    SomethingElse: {
        someOtherChannel: "foo/faa/fee"
    }
};
