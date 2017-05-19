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

module VuidRestActions
  ACTION_ALLOCATE = :allocate
end

module VuidRest
  include VuidRestActions
  include CommonActionSyms
  extend self

  #always name the root_path ROOT_PATH!
  ROOT_PATH = ISAAC_ROOT + 'rest/1/vuids/'
  PATH_ALLOCATE = ROOT_PATH + 'allocate'

  # these are not used!!
  PARAMS_EMPTY = {}

  ACTION_CONSTANTS = {
      ACTION_ALLOCATE => {
          PATH_SYM => PATH_ALLOCATE,
          STARTING_PARAMS_SYM => PARAMS_EMPTY,
          CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api::Data::Vuid::RestVuidBlockData}
  }

  class << self
    #attr_accessor :instance_data
  end

  class Vuid < CommonRestBase::RestBase
    include CommonRest
    register_rest(rest_module: VuidRest, rest_actions: VuidRestActions)

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

  def get_vuid_api(action:, additional_req_params: nil)
    Vuid.new(action: action,  params: additional_req_params, action_constants: ACTION_CONSTANTS).rest_call
  end
end

=begin
load('./lib/isaac_rest/vuid_rest.rb')

allocate = VuidRest::get_search_api(action: VuidRestActions::ACTION_ALLOCATE,  additional_req_params: {blockSize: 1, reason: 'Testing'} )
=end

