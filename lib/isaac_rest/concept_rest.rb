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

module ConceptRestActions
  ACTION_VERSION = :version
  ACTION_DESCRIPTIONS = :descriptions
  ACTION_CHRONOLOGY = :chronology
end

module ConceptRest
  include ConceptRestActions
  include CommonActionSyms
  extend self

  CONCEPT_PATH = ISAAC_ROOT + 'rest/1/concept/'
  CHRONOLOGY_CONCEPT_PATH = CONCEPT_PATH + 'chronology/{id}'
  VERSION_CONCEPT_PATH = CONCEPT_PATH + 'version/{id}'
  DESCRIPTIONS_CONCEPT_PATH = CONCEPT_PATH + 'descriptions/{id}'
  TEST_UUID = 'a60bd881-9010-3260-9653-0c85716b4391' #useful for testing

  CHRONOLOGY_CONCEPT_STARTING_PARAMS = {}
  VERSION_CONCEPT_STARTING_PARAMS = {}
  DESCRIPTIONS_CONCEPT_STARTING_PARAMS = {}

  ACTION_CONSTANTS = {
      ACTION_VERSION => {PATH_SYM => VERSION_CONCEPT_PATH,
                         STARTING_PARAMS_SYM => VERSION_CONCEPT_STARTING_PARAMS,
                         CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Concept::RestConceptVersion},
      ACTION_DESCRIPTIONS => {PATH_SYM => DESCRIPTIONS_CONCEPT_PATH,
                              STARTING_PARAMS_SYM => DESCRIPTIONS_CONCEPT_STARTING_PARAMS,
                              CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Sememe::RestSememeDescriptionVersion},
      ACTION_CHRONOLOGY => {PATH_SYM => CHRONOLOGY_CONCEPT_PATH,
                            STARTING_PARAMS_SYM => CHRONOLOGY_CONCEPT_STARTING_PARAMS,
                            CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Concept::RestConceptChronology}
  }

  class << self
    #attr_accessor :instance_data
  end

  class Concept < CommonRestBase::RestBase
    include CommonRest
    register_rest(rest_module: ConceptRest, rest_actions: ConceptRestActions)
    attr_accessor :uuid

    def initialize(uuid:, params:, action:, action_constants:)
      @uuid = uuid.to_s unless uuid.nil?
      uuid_check uuid: uuid
      super(params: params, action: action, action_constants: action_constants)
    end

    def rest_call
      url = get_url
      url_string = url.gsub('{id}', uuid)
      json = rest_fetch(url_string: url_string, params: get_params, raw_url: url)
      enunciate_json(json)
    end
  end

  def main_fetch(**hash)
    get_concept(action: hash[:action], uuid: hash[:id], additional_req_params: hash[:params])
  end

  def get_concept(action:, uuid:, additional_req_params: nil)
    Concept.new(uuid: uuid, params: additional_req_params, action:  action, action_constants: ACTION_CONSTANTS).rest_call
  end
end

=begin
load('./lib/isaac_rest/concept_rest.rb')
a = ConceptRest::get_concept(action: ConceptRestActions::ACTION_DESCRIPTIONS,uuid: 'cc0b2455-f546-48fa-90e8-e214cc8478d6')
b = ConceptRest::get_concept(action: ConceptRestActions::ACTION_CHRONOLOGY,uuid: 'cc0b2455-f546-48fa-90e8-e214cc8478d6')
c = ConceptRest::get_concept(action: ConceptRestActions::ACTION_VERSION,uuid: 'cc0b2455-f546-48fa-90e8-e214cc8478d6')
#note this will fail!  Use the module ConceptRestActions!!
# c = ConceptRest::get_concept(action: "version",uuid: 'cc0b2455-f546-48fa-90e8-e214cc8478d6')
#  a = Concept.new(uuid: "ddd", params: nil, action: :version, action_constants: ACTION_CONSTANTS)
=end