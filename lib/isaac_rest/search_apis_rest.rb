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
end

module SearchApis
  include SearchApiActions
  include CommonActionSyms
  extend self

  PATH_SEARCH_API = $PROPS['ENDPOINT.isaac_root'] + 'rest/1/search/'
  PATH_DESCRIPTIONS = PATH_SEARCH_API + 'descriptions'
  PATH_PREFIX = PATH_SEARCH_API + 'prefix'

  # these are not used!!
  PARAMS_DESCRIPTIONS = {}
  PARAMS_PREFIX = {}

  ACTION_CONSTANTS = {
      ACTION_DESCRIPTIONS => {
          PATH_SYM => PATH_DESCRIPTIONS,
          STARTING_PARAMS_SYM => PARAMS_DESCRIPTIONS,
          CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Search::RestSearchResult},
      ACTION_PREFIX => {
          PATH_SYM => PATH_PREFIX,
          STARTING_PARAMS_SYM => PARAMS_PREFIX,
          CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Search::RestSearchResult}
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
      json = rest_fetch(url_string: url, params: get_params, raw_url: url)
      enunciate_json(json)
    end
  end

  def main_fetch(**hash)
    get_search_api(action: hash[:action])
  end

  def get_search_api(action:, additional_req_params: nil)
    SearchApi.new(action: action,  params: additional_req_params, action_constants: ACTION_CONSTANTS).rest_call
  end
end

=begin
load('./lib/isaac_rest/search_apis_rest.rb')

heart = SearchApis::get_search_api(action: SearchApiActions::ACTION_DESCRIPTIONS,  additional_req_params: {descriptionType: 'fsn', query: 'heart'} )
failure = SearchApis::get_search_api(action: SearchApiActions::ACTION_DESCRIPTIONS,  additional_req_params: {descriptionType: 'fsn', query: 'failure', limit: 20} )
prefix = SearchApis::get_search_api(action: SearchApiActions::ACTION_PREFIX,  additional_req_params: {query: 'failure', limit: 20} )

=end

