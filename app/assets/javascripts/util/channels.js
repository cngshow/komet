/**
 * All Channel strings must be unique even across namespaces!
 * Thus if EtsChannels.Taxonomy has:
 * taxonomyTreeNodeOpenedChannel: "Taxonomy/TaxonomyTree/NodeOpened"
 * the value string cannot be used again!!
 */
var EtsChannels = {

     Taxonomy : {
        //These strings must be unique across  all channels
        taxonomyTreeNodeOpenedChannel: "Taxonomy/TaxonomyTree/NodeOpened",
        taxonomyTreeNodeClosedChannel: "Taxonomy/TaxonomyTree/NodeClosed"
    },
    //whoever adds in another real namespace can whack this silly example
     SomethingElse : {
        someOtherChannel: "foo/faa/fee"
    }

}