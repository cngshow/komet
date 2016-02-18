##
# Do common initialization tasks in ets tooling
#
require './lib/ets_common/props/prop_loader'
require './lib/ets_common/logging/open_logging'
require './lib/ets_common/logging/logging'
require './lib/utilities/cached_hash'
require './lib/ets_common/util/helpers'

$rest_cache = CachedHash.new($PROPS.fetch('ETS.rest_cache_max').to_i)
