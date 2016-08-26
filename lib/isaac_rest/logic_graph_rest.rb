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

module LogicGraphRestActions
  ACTION_CHRONOLOGY = :chronology
  ACTION_VERSION = :version
end

module LogicGraphRest
  include LogicGraphRestActions
  include CommonActionSyms
  extend self

  #always name the root_path ROOT_PATH!
  ROOT_PATH = ISAAC_ROOT + 'rest/1/logicGraph/'
  CHRONOLOGY_PATH = ROOT_PATH + 'chronology/{id}'
  VERSION_PATH = ROOT_PATH + 'version/{id}'

  TEST_UUID = '406e872b-2e19-5f5e-a71d-e4e4b2c68fe5'

  CHRONOLOGY_STARTING_PARAMS = {}
  VERSION_STARTING_PARAMS = {}

  ACTION_CONSTANTS = {
      ACTION_CHRONOLOGY => {PATH_SYM => CHRONOLOGY_PATH, STARTING_PARAMS_SYM => CHRONOLOGY_STARTING_PARAMS, CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Sememe::RestSememeChronology},
      ACTION_VERSION => {PATH_SYM => VERSION_PATH, STARTING_PARAMS_SYM => VERSION_STARTING_PARAMS, CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Sememe::RestSememeLogicGraphVersion},
  }


  class << self
    #attr_accessor :instance_data
  end

  class LogicGraph < CommonRestBase::RestBase
    include CommonRest
    register_rest(rest_module: LogicGraphRest, rest_actions: LogicGraphRestActions)

    attr_accessor :uuid

    def initialize(uuid:, params:, action:, action_constants:)
      @uuid = uuid.to_s unless uuid.nil?
      uuid_check uuid: uuid
      super(params: params, action: action, action_constants: action_constants)
    end

    def rest_call(enunciated = true)
      p = get_params
      url = get_url
      url_string = url.gsub('{id}', uuid)
      json = rest_fetch(url_string: url_string, params: p, raw_url: url)
      if(enunciated)
        return  enunciate_json(json)
      else
        return json
      end
    end
  end

  def main_fetch(**hash)
    get_graph(action: hash[:action], uuid_or_id: hash[:id], additional_req_params: hash[:params])
  end

  def get_graph(action:, uuid_or_id:, additional_req_params: nil, raw_json: false)
    LogicGraph.new(uuid: uuid_or_id, params: additional_req_params, action: action, action_constants: ACTION_CONSTANTS).rest_call(!raw_json)
  end
end

=begin
load('./lib/isaac_rest/logic_graph_rest.rb')
a = LogicGraphRest::get_graph(action: LogicGraphRestActions::ACTION_CHRONOLOGY,uuid_or_id: LogicGraphRest::TEST_UUID)
b = LogicGraphRest::get_graph(action: LogicGraphRestActions::ACTION_VERSION,uuid_or_id: LogicGraphRest::TEST_UUID)
s = LogicGraphRest.get_graph(action: ACTION_VERSION, uuid_or_id: "251be9d9-0193-3c98-9d11-317658983101", additional_req_params: {},raw_json: true)

#no caching!!!!
#just add the key as follows to your additional req params.  Its absence implies caching will occur, but you can be explicit and set it to true
#This key is never part of the request in the get, put or post.  We use an unmarshallable ruby object to ensure this.
uncached = LogicGraphRest::get_graph(action: LogicGraphRestActions::ACTION_CHRONOLOGY,uuid_or_id: LogicGraphRest::TEST_UUID,  additional_req_params: {CommonRest::CacheRequest => false})

=end

