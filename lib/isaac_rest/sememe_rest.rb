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

module SememeRestActions
  ACTION_VERSION = :version
  ACTION_CHRONOLOGY = :chronology
  ACTION_BY_REFERENCED_COMPONENT = :referenced_component
  ACTION_BY_ASSEMBLAGE = :by_assemblage
  ACTION_SEMEME_DEFINITION = :sememe_definition
end

module SememeRest
  include SememeRestActions
  include CommonActionSyms
  extend self

  SEMEME_PATH = $PROPS['ENDPOINT.isaac_root'] + "rest/1/sememe/"
  CHRONOLOGY_SEMEME_PATH = SEMEME_PATH + "chronology/{id}"
  VERSION_SEMEME_PATH = SEMEME_PATH + "version/{id}"
  BY_REFERENCED_COMPONENT_SEMEME_PATH = SEMEME_PATH + "byReferencedComponent/{id}"
  BY_ASSEMBLAGE_SEMEME_PATH = SEMEME_PATH + "byAssemblage/{id}"
  DEFINITION_SEMEME_PATH = SEMEME_PATH + "sememeDefinition/{id}"
  TEST_ID = "1349" #useful for testing the actions VERSION, CHRONOLOGY, BY_ASSEMBLAGE
  TEST_UUID_REF_COMP = "cc0b2455-f546-48fa-90e8-e214cc8478d6"
  TEST_UUID_SEMEME_DEF = "406e872b-2e19-5f5e-a71d-e4e4b2c68fe5"

  CHRONOLOGY_SEMEME_STARTING_PARAMS = {}
  VERSION_SEMEME_STARTING_PARAMS = {}
  BY_REFERENCED_COMPONENT_SEMEME_STARTING_PARAMS = {}
  BY_ASSEMBLAGE_SEMEME_STARTING_PARAMS = {}
  DEFINITION_SEMEME_STARTING_PARAMS = {}

  ACTION_CONSTANTS = {
      ACTION_VERSION => {PATH_SYM => VERSION_SEMEME_PATH, STARTING_PARAMS_SYM => VERSION_SEMEME_STARTING_PARAMS, CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Sememe::RestSememeDescriptionVersion},
      ACTION_BY_REFERENCED_COMPONENT => {PATH_SYM => BY_REFERENCED_COMPONENT_SEMEME_PATH, STARTING_PARAMS_SYM => BY_REFERENCED_COMPONENT_SEMEME_STARTING_PARAMS, CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Sememe::RestSememeDescriptionVersion},
      ACTION_CHRONOLOGY => {PATH_SYM => CHRONOLOGY_SEMEME_PATH, STARTING_PARAMS_SYM => CHRONOLOGY_SEMEME_STARTING_PARAMS, CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Sememe::RestSememeChronology},
      ACTION_BY_ASSEMBLAGE => {PATH_SYM => BY_ASSEMBLAGE_SEMEME_PATH, STARTING_PARAMS_SYM => BY_ASSEMBLAGE_SEMEME_STARTING_PARAMS, CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Sememe::RestSememeVersion},
      ACTION_SEMEME_DEFINITION => {PATH_SYM => DEFINITION_SEMEME_PATH, STARTING_PARAMS_SYM => DEFINITION_SEMEME_STARTING_PARAMS, CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Sememe::RestDynamicSememeDefinition}
  }

  class << self
    #attr_accessor :instance_data
  end

  class Sememe < CommonRestBase::RestBase
    include CommonRest
    register_rest(rest_module: SememeRest, rest_actions: SememeRestActions)

    attr_accessor :uuid

    def initialize(uuid:, params:, action:, action_constants:)
      @uuid = uuid
      uuid_check uuid: uuid
      super(params: params, action: action, action_constants: action_constants)
    end

    def rest_call
      r_val = nil
      p = get_params
      url = get_url
      url_string = url.gsub('{id}', uuid)
      json = rest_fetch(url_string: url_string, params: p, raw_url: url)
      enunciate_json(json)
    end
  end

  def main_fetch(**hash)
    get_sememe(action: hash[:action], uuid_or_id: hash[:id], additional_req_params: hash[:params])
  end

  def get_sememe(action:, uuid_or_id:, additional_req_params: nil)
    Sememe.new(uuid: uuid_or_id, params: additional_req_params, action: action, action_constants: ACTION_CONSTANTS).rest_call
  end
end

=begin
load('./lib/isaac_rest/sememe_rest.rb')
a = SememeRest::get_sememe(action: SememeRestActions::ACTION_BY_REFERENCED_COMPONENT,uuid_or_id: SememeRest::TEST_UUID_REF_COMP)
b = SememeRest::get_sememe(action: SememeRestActions::ACTION_CHRONOLOGY,uuid_or_id: SememeRest::TEST_ID)
c = SememeRest::get_sememe(action: SememeRestActions::ACTION_VERSION,uuid_or_id: SememeRest::TEST_ID)
d = SememeRest::get_sememe(action: SememeRestActions::ACTION_BY_ASSEMBLAGE,uuid_or_id: SememeRest::TEST_ID)
e = SememeRest::get_sememe(action: SememeRestActions::ACTION_SEMEME_DEFINITION,uuid_or_id: SememeRest::TEST_UUID_SEMEME_DEF)
=end

