=begin
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
=end
require './lib/isaac_rest/common_rest'

module SearchApiActions
  ACTION_DESCRIPTIONS = :descriptions
  ACTION_PREFIX = :prefix
  ACTION_SEMEMES = :sememes
  ACTION_BY_REFERENCED_COMPONENT = :by_referenced_component
  ACTION_ID = :id
end

module SearchApis
  include SearchApiActions
  include CommonActionSyms
  extend self

  #always name the root_path ROOT_PATH!
  ROOT_PATH = ISAAC_ROOT + 'rest/1/search/'
  PATH_DESCRIPTIONS = ROOT_PATH + 'descriptions'
  PATH_PREFIX = ROOT_PATH + 'prefix'
  PATH_SEMEMES = ROOT_PATH + 'sememes'
  PATH_BY_REFERENCED_COMPONENT = ROOT_PATH + 'forReferencedComponent'
  PATH_ID = ROOT_PATH + 'id'

  # these are not used!!
  PARAMS_EMPTY = {}

  ACTION_CONSTANTS = {
      ACTION_DESCRIPTIONS => {
          PATH_SYM => PATH_DESCRIPTIONS,
          STARTING_PARAMS_SYM => PARAMS_EMPTY,
          CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Search::RestSearchResultPage},
      ACTION_PREFIX => {
          PATH_SYM => PATH_PREFIX,
          STARTING_PARAMS_SYM => PARAMS_EMPTY,
          CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Search::RestSearchResultPage},
      ACTION_SEMEMES => {
          PATH_SYM => PATH_SEMEMES,
          STARTING_PARAMS_SYM => PARAMS_EMPTY,
          CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Search::RestSearchResultPage},
      ACTION_BY_REFERENCED_COMPONENT => {
          PATH_SYM => PATH_BY_REFERENCED_COMPONENT,
          STARTING_PARAMS_SYM => PARAMS_EMPTY,
          CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Search::RestSearchResultPage},
      ACTION_ID => {
          PATH_SYM => PATH_ID,
          STARTING_PARAMS_SYM => PARAMS_EMPTY,
          CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Search::RestSearchResultPage},
  }

  class << self
    #attr_accessor :instance_data
  end

  class SearchApi < CommonRestBase::RestBase
    include CommonRest
    register_rest(rest_module: SearchApis, rest_actions: SearchApiActions)

    def initialize(action:,  params:, action_constants:)
      super(params: params, action: action, action_constants: action_constants)
    end

    def rest_call
      json = rest_fetch(url_string: get_url, params: get_params, raw_url: get_url)
      enunciate_json(json)
    end
  end

  def main_fetch(**hash)
    get_search_api(action: hash[:action], additional_req_params: hash[:params])
  end

  def get_search_api(action:, additional_req_params: nil)
    SearchApi.new(action: action,  params: additional_req_params, action_constants: ACTION_CONSTANTS).rest_call
  end
end

=begin
load('./lib/isaac_rest/search_apis_rest.rb')

heart = SearchApis::get_search_api(action: SearchApiActions::ACTION_DESCRIPTIONS,  additional_req_params: {descriptionType: 'fsn', query: 'heart'} )
heart_expanded = SearchApis::get_search_api(action: SearchApiActions::ACTION_DESCRIPTIONS,  additional_req_params: {descriptionType: 'fsn', query: 'heart',expand: 'uuid,referencedConcept'} )
snomed = SearchApis::get_search_api(action: SearchApiActions::ACTION_DESCRIPTIONS,  additional_req_params: {descriptionType: 'fsn', query: 'snomed'} )
failure = SearchApis::get_search_api(action: SearchApiActions::ACTION_DESCRIPTIONS,  additional_req_params: {descriptionType: 'fsn', query: 'failure'} )
prefix = SearchApis::get_search_api(action: SearchApiActions::ACTION_PREFIX,  additional_req_params: {query: 'failure'} )

# THESE ARE MEANT FOR VHAT BUT FIRST 2 WORK ON SNOMED
s1 = SearchApis::get_search_api(action: SearchApiActions::ACTION_SEMEMES, additional_req_params: {query: '1'} )
s2 = SearchApis::get_search_api(action: SearchApiActions::ACTION_SEMEMES, additional_req_params: {query: '(1,4)'} )
s3 = SearchApis::get_search_api(action: SearchApiActions::ACTION_SEMEMES, additional_req_params: {query: 'hair%20NOT%20loss'} )
s4 = SearchApis::get_search_api(action: SearchApiActions::ACTION_SEMEMES, additional_req_params: {query: 'hair%20OR%20SKIN'} )

# BY_REFERENCED_COMPONENT calls
brc1 = SearchApis::get_search_api(action: SearchApiActions::ACTION_BY_REFERENCED_COMPONENT, additional_req_params: {nid: '-2147483628'} )
brc2 = SearchApis::get_search_api(action: SearchApiActions::ACTION_BY_REFERENCED_COMPONENT, additional_req_params: {nid: '-2147483628', sememeAssemblageSequence: 1} )
=end

