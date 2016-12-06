##
# Do common initialization tasks in komet tooling
#

# Only add one number after the decimal for the API version match
REST_API_VERSIONS = [:"1.9"].freeze

require './lib/rails_common/props/prop_loader'
require './lib/rails_common/logging/open_logging'
require './lib/rails_common/logging/logging'
require './lib/utilities/cached_hash'
require './lib/rails_common/util/helpers'
require './lib/rails_common/logging/prisme_log_event'
ISAAC_ROOT = ENV['ISAAC_ROOT'].nil? ? '' : ENV['ISAAC_ROOT']

$isaac_hunter_mutex = Mutex.new #Not re-entrant, but lock acquires in 1/2 the time (After JVM is warm and toasty).

unless $rake
  Thread.new do
    $isaac_hunter_mutex.synchronize do
      v = $VERBOSE
      $VERBOSE = nil

      final_root = ''
      #All the rest libs depend on ISAAC_ROOT.   The line below must be above those requires.
      if ($PROPS['PRISME.isaac_root'])
        ir = $PROPS['PRISME.isaac_root']
        ir << '/' unless ir[-1].eql?('/')
        ISAAC_ROOT = ir
      else
        root_possibilites = eval $PROPS['ENDPOINT.isaac_root']
        root_possibilites.each do |url|
          if KOMETUtilities::isaac_rest_site_up?(uri: URI(url))
            final_root = url
            break
          end
        end
        ISAAC_ROOT = final_root
      end
      $log.always("I am pointed to #{ISAAC_ROOT}")
      $VERBOSE = v
      ###############################################
      ######### COMMON REST IMPORTS GO HERE!!!!!!
      require './lib/isaac_rest/association_rest'
      require './lib/isaac_rest/logic_graph_rest'
      require './lib/isaac_rest/concept_rest'
      require './lib/isaac_rest/component_rest'
      require './lib/isaac_rest/id_apis_rest'
      require './lib/isaac_rest/search_apis_rest'
      require './lib/isaac_rest/sememe_rest'
      require './lib/isaac_rest/system_apis_rest'
      require './lib/isaac_rest/taxonomy_rest'
      require './lib/isaac_rest/coordinate_rest'
      require './lib/isaac_rest/mapping_apis_rest'
      require './lib/isaac_rest/comment_apis_rest'
      #require './lib/isaac_rest/workflow_rest'
      require './lib/isaac_rest/export_rest'
      ######### COMMON REST IMPORTS GO HERE!!!!!!
      #####################################################
    end
  end
end

#in developer mode it is nice to have the rest classes fully loaded so all the registration takes place, for example:
#register_rest(rest_module: LogicGraphRest, rest_actions: LogicGraphRestActions)
#This ensures the rails console plays nice.
require './lib/rails_common/util/bootstrap_notifier'#above roles (roles references these libs)
require './lib/rails_common/roles/roles'

$rest_cache = CachedHash.new($PROPS.fetch('KOMET.rest_cache_max').to_i)

at_exit do
  context = ($CONTEXT.eql?('/')) ? '' : $CONTEXT
  $log.always_n(PrismeLogEvent::LIFECYCLE_TAG, "#{Rails.application.class.parent_name}/#{context} has been ruthlessly executed!", false) unless $rake
end

# Thread.new do
#   sleep 3
#   #concept = SememeRest::get_sememe(action: SememeRestActions::ACTION_CHRONOLOGY, uuid_or_id: '-2145065647', additional_req_params: {expand: 'versionsAll'})
#   #c = CoordinateRest::get_coordinate(action: CoordinateRestActions::ACTION_LANGUAGE_COORDINATE)
#   while true
#     begin
#       set_test = MappingApis::get_mapping_api(action: MappingApiActions::ACTION_SET, uuid_or_id: "a9262b1e-f650-5440-9d0d-edf75851ce91" ) # run this for testing
#       a = set_test.mapSetExtendedFields[0].extensionValue #wrong class
#     rescue => ex
#       p ex
#     end
#     puts "yay!"
#   end
# end


# Thread.new do
#   sleep 3
#   #concept = SememeRest::get_sememe(action: SememeRestActions::ACTION_CHRONOLOGY, uuid_or_id: '-2145065647', additional_req_params: {expand: 'versionsAll'})
#   #c = CoordinateRest::get_coordinate(action: CoordinateRestActions::ACTION_LANGUAGE_COORDINATE)
#   while true
#     begin
#       set_test = MappingApis::get_mapping_api(action: MappingApiActions::ACTION_SET, uuid_or_id: "a9262b1e-f650-5440-9d0d-edf75851ce91" ) # run this for testing
#       a = set_test.mapSetExtendedFields[0].extensionValue #wrong class
#     rescue => ex
#       p ex
#     end
#     puts "yay!"
#   end
# end\
#
# Thread.new do
#   sleep 3
#   #concept = SememeRest::get_sememe(action: SememeRestActions::ACTION_CHRONOLOGY, uuid_or_id: '-2145065647', additional_req_params: {expand: 'versionsAll'})
#   #c = CoordinateRest::get_coordinate(action: CoordinateRestActions::ACTION_LANGUAGE_COORDINATE)
#   while true
#     begin
#       set_test = MappingApis::get_mapping_api(action: MappingApiActions::ACTION_SET, uuid_or_id: "a9262b1e-f650-5440-9d0d-edf75851ce91" ) # run this for testing
#       a = set_test.mapSetExtendedFields[0].extensionValue #wrong class
#     rescue => ex
#       p ex
#     end
#     puts "yay!"
#   end
# end
#Another check in test