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
    ACTION_CREATE = :create
    ACTION_UPDATE = :update
end

module ConceptRest
    include ConceptRestActions
    include CommonActionSyms
    extend self

    #always name the root_path ROOT_PATH!
    ROOT_PATH = ISAAC_ROOT + 'rest/1/concept/'
    PATH_CONCEPT_WRITE = ISAAC_ROOT + 'rest/write/1/concept/'
    PATH_CHRONOLOGY_CONCEPT = ROOT_PATH + 'chronology/{id}'
    PATH_VERSION_CONCEPT = ROOT_PATH + 'version/{id}'
    PATH_DESCRIPTIONS_CONCEPT = ROOT_PATH + 'descriptions/{id}'
    PATH_CREATE_CONCEPT = PATH_CONCEPT_WRITE + 'create'
    PATH_UPDATE_CONCEPT = PATH_CONCEPT_WRITE + 'update/{id}'
    TEST_UUID = 'a60bd881-9010-3260-9653-0c85716b4391' #useful for testing

    PARAMS_EMPTY = {}

    ACTION_CONSTANTS = {
        ACTION_VERSION => {
            PATH_SYM => PATH_VERSION_CONCEPT,
            STARTING_PARAMS_SYM => PARAMS_EMPTY,
            CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Concept::RestConceptVersion},
        ACTION_DESCRIPTIONS => {
            PATH_SYM => PATH_DESCRIPTIONS_CONCEPT,
            STARTING_PARAMS_SYM => PARAMS_EMPTY,
            CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Sememe::RestSememeDescriptionVersion},
        ACTION_CHRONOLOGY => {
            PATH_SYM => PATH_CHRONOLOGY_CONCEPT,
            STARTING_PARAMS_SYM => PARAMS_EMPTY,
            CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Concept::RestConceptChronology},
        ACTION_CREATE => {
            PATH_SYM => PATH_CREATE_CONCEPT,
            STARTING_PARAMS_SYM => PARAMS_EMPTY,
            CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api::Data::Wrappers::RestWriteResponse,
            HTTP_METHOD_KEY => HTTP_METHOD_POST,
            BODY_CLASS => Gov::Vha::Isaac::Rest::Api1::Data::Concept::RestConceptCreateData},
        ACTION_UPDATE => {
            PATH_SYM => PATH_UPDATE_CONCEPT,
            STARTING_PARAMS_SYM => PARAMS_EMPTY,
            CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api::Data::Wrappers::RestWriteResponse,
            HTTP_METHOD_KEY => HTTP_METHOD_PUT,
            BODY_CLASS => Gov::Vha::Isaac::Rest::Api1::Data::Concept::RestConceptUpdateData}
    }

    class << self
        #attr_accessor :instance_data
    end

    class Concept < CommonRestBase::RestBase
        include CommonRest
        register_rest(rest_module: ConceptRest, rest_actions: ConceptRestActions)
        attr_accessor :uuid

        def initialize(uuid:, params:, body_params:, action:, action_constants:)
            @uuid = uuid.to_s unless uuid.nil?
            uuid_check uuid: uuid unless [ConceptRestActions::ACTION_CREATE].include?(action)
            super(params: params, body_params: body_params, action: action, action_constants: action_constants)
        end

        def rest_call
            url = get_url
            url_string = uuid.nil? ? url : url.gsub('{id}', uuid)
            json = rest_fetch(url_string: url_string, params: get_params, body_params: body_params, raw_url: url)
            enunciate_json(json)
        end
    end

    def main_fetch(**hash)
        get_concept(action: hash[:action], uuid: hash[:id], additional_req_params: hash[:params], body_params: hash[:body_params])
    end

    def get_concept(action:, uuid: nil, additional_req_params: nil, body_params: {})
        Concept.new(uuid: uuid, params: additional_req_params, body_params: body_params, action: action, action_constants: ACTION_CONSTANTS).rest_call
    end
end

=begin
load('./lib/isaac_rest/concept_rest.rb')
a = ConceptRest::get_concept(action: ConceptRestActions::ACTION_DESCRIPTIONS,uuid: 'cc0b2455-f546-48fa-90e8-e214cc8478d6')
b = ConceptRest::get_concept(action: ConceptRestActions::ACTION_CHRONOLOGY,uuid: 'cc0b2455-f546-48fa-90e8-e214cc8478d6')
c = ConceptRest::get_concept(action: ConceptRestActions::ACTION_VERSION,uuid: 'cc0b2455-f546-48fa-90e8-e214cc8478d6')
#TODO - need to figure out passing editToken into write calls
#create = ConceptRest::get_concept(action: ConceptRestActions::ACTION_CREATE, additional_req_params: {editToken: }, body_params: {fsn: 'Concept Create Test 1', descriptionLanguageConceptId: 8, parentConceptIds: [11] } )
#update = ConceptRest::get_concept(action: ConceptRestActions::ACTION_UPDATE, additional_req_params: {editToken: }, uuid: 'cc0b2455-f546-48fa-90e8-e214cc8478d6, body_params: {active: true})
=end