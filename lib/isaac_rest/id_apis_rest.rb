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

module IdAPIsRestActions
  ACTION_TYPES = :types
  ACTION_TRANSLATE = :translate
end

module IdAPIsRest
  include IdAPIsRestActions
  include CommonActionSyms
  extend self

  ID_APIS_PATH = $PROPS['ENDPOINT.isaac_root'] + 'rest/1/id/'
  TYPES_PATH = ID_APIS_PATH + 'types'
  TYPES_TRANSLATE_PATH = ID_APIS_PATH + 'translate/{id}'

  TEST_UUID = '406e872b-2e19-5f5e-a71d-e4e4b2c68fe5'

  TYPES_STARTING_PARAMS = {}
  TYPES_TRANSLATE_STARTING_PARAMS = {}

  #NOTE!!  The use of JSON as a class is a marker only.  It means, just return the straight JSON.  The JSON will be parsed
  # so expect an Array, a Hash, a String, or a FixNum!!!
  ACTION_CONSTANTS = {
      ACTION_TYPES => {PATH_SYM => TYPES_PATH, STARTING_PARAMS_SYM => TYPES_STARTING_PARAMS, CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Enumerations::RestSupportedIdType},
      ACTION_TRANSLATE => {PATH_SYM => TYPES_TRANSLATE_PATH, STARTING_PARAMS_SYM => TYPES_TRANSLATE_STARTING_PARAMS, CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::RestId},
 }

  class << self
    #attr_accessor :instance_data
  end

  class IdAPIs < CommonRestBase::RestBase
    include CommonRest
    register_rest(rest_module: IdAPIsRest, rest_actions: IdAPIsRestActions)

    attr_accessor :uuid

    def initialize(uuid:, params:, action:, action_constants:)
      @uuid = uuid.to_s unless uuid.nil?
      uuid_check uuid: uuid unless action.eql?(IdAPIsRestActions::ACTION_TYPES)
      super(params: params, action: action, action_constants: action_constants)
    end

    def rest_call
      p = get_params
      url = get_url
      url_string = uuid.nil? ? url : url.gsub('{id}', uuid) #types action doesn't need a uuid
      json = rest_fetch(url_string: url_string, params: p, raw_url: url)
      enunciate_json(json)
    end
  end

  def main_fetch(**hash)
    get_id(action: hash[:action], uuid_or_id: hash[:id], additional_req_params: hash[:params])
  end

  def get_id(action:, uuid_or_id: nil, additional_req_params: nil)
    IdAPIs.new(uuid: uuid_or_id, params: additional_req_params, action: action, action_constants: ACTION_CONSTANTS).rest_call
  end
end

=begin
load('./lib/isaac_rest/id_apis_rest.rb')
a = IdAPIsRest::get_id(action: IdAPIsRestActions::ACTION_TYPES)
b = IdAPIsRest::get_id(action: IdAPIsRestActions::ACTION_TRANSLATE,uuid_or_id: IdAPIsRest::TEST_UUID)
c = IdAPIsRest::get_id(action: IdAPIsRestActions::ACTION_TRANSLATE,uuid_or_id: IdAPIsRest::TEST_UUID,additional_req_params: {"outputType" => "nid"})
d = IdAPIsRest::get_id(action: IdAPIsRestActions::ACTION_TRANSLATE,uuid_or_id: "-2146638749",additional_req_params: {"outputType" => "uuid", "inputType" => "nid"})
e = IdAPIsRest::get_id(action: IdAPIsRestActions::ACTION_TRANSLATE,uuid_or_id: "bad_uuid",additional_req_params: {"outputType" => "nid"})#test type
=end

