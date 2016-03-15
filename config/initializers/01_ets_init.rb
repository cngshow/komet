##
# Do common initialization tasks in ets tooling
#
require './lib/ets_common/props/prop_loader'
require './lib/ets_common/logging/open_logging'
require './lib/ets_common/logging/logging'
require './lib/utilities/cached_hash'
require './lib/ets_common/util/helpers'

#in developer mode it is nice to have the rest classes fully loaded so all the registration takes place, for example:
# register_rest(rest_module: LogicGraphRest, rest_actions: LogicGraphRestActions)
#This ensures the rails console plays nice.
require './lib/isaac_rest/logic_graph_rest'
require './lib/isaac_rest/concept_rest'
require './lib/isaac_rest/id_apis_rest'
require './lib/isaac_rest/search_apis_rest'
require './lib/isaac_rest/sememe_rest'
require './lib/isaac_rest/system_apis_rest'
require './lib/isaac_rest/taxonomy_rest'

$rest_cache = CachedHash.new($PROPS.fetch('ETS.rest_cache_max').to_i)
# Thread.new do
#   sleep 3
#   concept = SememeRest::get_sememe(action: SememeRestActions::ACTION_CHRONOLOGY, uuid_or_id: '-2145065647', additional_req_params: {expand: 'versionsAll'})
# end
#test check in