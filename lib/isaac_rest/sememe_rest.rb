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
    ACTION_SEMEME_TYPE = :sememe_type
    ACTION_DESCRIPTION_CREATE = :description_create
    ACTION_DESCRIPTION_UPDATE = :description_update
    ACTION_SEMEME_CREATE = :sememe_create
    ACTION_SEMEME_UPDATE = :sememe_update
end

module SememeRest
    include SememeRestActions
    include CommonActionSyms
    extend self

    #always name the root_path ROOT_PATH!
    ROOT_PATH = ISAAC_ROOT + 'rest/1/sememe/'
    PATH_CONCEPT_WRITE = ISAAC_ROOT + 'rest/write/1/sememe/'
    
    PATH_CHRONOLOGY_SEMEME = ROOT_PATH + 'chronology/{id}'
    PATH_VERSION_SEMEME = ROOT_PATH + 'version/{id}'
    PATH_BY_REFERENCED_COMPONENT_SEMEME = ROOT_PATH + 'byReferencedComponent/{id}'
    PATH_BY_ASSEMBLAGE_SEMEME = ROOT_PATH + 'byAssemblage/{id}'
    PATH_DEFINITION_SEMEME = ROOT_PATH + 'sememeDefinition/{id}'
    PATH_TYPE_SEMEME = ROOT_PATH + 'sememeType/{id}'

    PATH_DESCRIPTION_CREATE = PATH_CONCEPT_WRITE + 'description/create'
    PATH_DESCRIPTION_UPDATE = PATH_CONCEPT_WRITE + 'description/update/{id}'
    PATH_SEMEME_CREATE = PATH_CONCEPT_WRITE + 'create/'
    PATH_SEMEME_UPDATE = PATH_CONCEPT_WRITE + 'update/{id}'

    TEST_ID = '3621bf47-a54c-5f6e-a68d-c4dcb7156815'#'a60bd881-9010-3260-9653-0c85716b4391' #'1f5bd727-27c5-59b9-bcc3-964d6155a010'#19554b92-9025-554b-8fa1-1d1d95fe57f4'#useful for testing the actions VERSION, CHRONOLOGY, BY_ASSEMBLAGE
    TEST_ASSEMBLAGE_ID = '3e0cd740-2cc6-3d68-ace7-bad2eb2621da'
    TEST_SEMEME_TYPE_ID = '3621bf47-a54c-5f6e-a68d-c4dcb7156815'
    TEST_UUID_REF_COMP = 'a60bd881-9010-3260-9653-0c85716b4391'
    TEST_UUID_SEMEME_DEF = '4252fd31-3361-5105-bb43-65f390325e92'#'700546a3-09c7-3fc2-9eb9-53d318659a09'#'7c21b6c5-cf11-5af9-893b-743f004c97f5'#'4252fd31-3361-5105-bb43-65f390325e92'#'fb28bac9-c76a-56b5-af4d-5e60eeba328b'#"406e872b-2e19-5f5e-a71d-e4e4b2c68fe5"

    PARAMS_EMPTY = {}

    ACTION_CONSTANTS = {
        ACTION_VERSION => {
            PATH_SYM => PATH_VERSION_SEMEME, 
            STARTING_PARAMS_SYM => PARAMS_EMPTY, 
            CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Sememe::RestSememeDescriptionVersion},
        ACTION_BY_REFERENCED_COMPONENT => {
            PATH_SYM => PATH_BY_REFERENCED_COMPONENT_SEMEME, 
            STARTING_PARAMS_SYM => PARAMS_EMPTY, 
            CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Sememe::RestSememeDescriptionVersion},
        ACTION_CHRONOLOGY => {
            PATH_SYM => PATH_CHRONOLOGY_SEMEME, 
            STARTING_PARAMS_SYM => PARAMS_EMPTY, 
            CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Sememe::RestSememeChronology},
        ACTION_BY_ASSEMBLAGE => {
            PATH_SYM => PATH_BY_ASSEMBLAGE_SEMEME, 
            STARTING_PARAMS_SYM => PARAMS_EMPTY, 
            CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Sememe::RestSememeVersionPage},
        ACTION_SEMEME_DEFINITION => {
            PATH_SYM => PATH_DEFINITION_SEMEME, 
            STARTING_PARAMS_SYM => PARAMS_EMPTY, 
            CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Sememe::RestDynamicSememeDefinition},
        ACTION_SEMEME_TYPE => {
            PATH_SYM => PATH_TYPE_SEMEME, 
            STARTING_PARAMS_SYM => PARAMS_EMPTY, 
            CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Enumerations::RestSememeType},
        ACTION_DESCRIPTION_CREATE => {
            PATH_SYM => PATH_DESCRIPTION_CREATE,
            STARTING_PARAMS_SYM => PARAMS_EMPTY,
            CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api::Data::Wrappers::RestWriteResponse,
            HTTP_METHOD_KEY => HTTP_METHOD_POST,
            BODY_CLASS => Gov::Vha::Isaac::Rest::Api1::Data::Sememe::RestSememeDescriptionCreateData},
        ACTION_DESCRIPTION_UPDATE => {
            PATH_SYM => PATH_DESCRIPTION_UPDATE, 
            STARTING_PARAMS_SYM => PARAMS_EMPTY,
            CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api::Data::Wrappers::RestWriteResponse,
            HTTP_METHOD_KEY => HTTP_METHOD_PUT,
            BODY_CLASS => Gov::Vha::Isaac::Rest::Api1::Data::Sememe::RestSememeDescriptionUpdateData},
        ACTION_SEMEME_CREATE => {
            PATH_SYM => PATH_SEMEME_CREATE,
            STARTING_PARAMS_SYM => PARAMS_EMPTY,
            CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api::Data::Wrappers::RestWriteResponse,
            HTTP_METHOD_KEY => HTTP_METHOD_POST,
            BODY_CLASS => Gov::Vha::Isaac::Rest::Api1::Data::Sememe::RestDynamicSememeBaseCreate},
        ACTION_SEMEME_UPDATE => {
            PATH_SYM => PATH_SEMEME_UPDATE,
            STARTING_PARAMS_SYM => PARAMS_EMPTY,
            CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api::Data::Wrappers::RestWriteResponse,
            HTTP_METHOD_KEY => HTTP_METHOD_PUT,
            BODY_CLASS => Gov::Vha::Isaac::Rest::Api1::Data::Sememe::RestDynamicSememeBase}
    }

    class << self
        #attr_accessor :instance_data
    end

    class Sememe < CommonRestBase::RestBase
        include CommonRest
        register_rest(rest_module: SememeRest, rest_actions: SememeRestActions)

        attr_accessor :uuid

        def initialize(uuid:, params:, body_params:, action:, action_constants:)
            @uuid = uuid.to_s unless uuid.nil?
            uuid_check uuid: uuid unless [SememeRestActions::ACTION_DESCRIPTION_CREATE, SememeRestActions::ACTION_SEMEME_CREATE].include?(action)
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
        get_sememe(action: hash[:action], uuid_or_id: hash[:id], additional_req_params: hash[:params], body_params: hash[:body_params])
    end

    def get_sememe(action:, uuid_or_id: nil, additional_req_params: nil, body_params: {})
        Sememe.new(uuid: uuid_or_id, params: additional_req_params, body_params: body_params, action: action, action_constants: ACTION_CONSTANTS).rest_call
    end
end
# TODO - add write tests and need to figure out passing editToken into write calls
=begin
load('./lib/isaac_rest/sememe_rest.rb')
a = SememeRest::get_sememe(action: SememeRestActions::ACTION_BY_REFERENCED_COMPONENT,uuid_or_id: SememeRest::TEST_UUID_REF_COMP)
a1 = SememeRest::get_sememe(action: SememeRestActions::ACTION_BY_REFERENCED_COMPONENT,uuid_or_id: "406e872b-2e19-5f5e-a71d-e4e4b2c68fe5",additional_req_params: ({expand: "chronology,nestedSememes"}))
b = SememeRest::get_sememe(action: SememeRestActions::ACTION_CHRONOLOGY,uuid_or_id: SememeRest::TEST_ID)
c = SememeRest::get_sememe(action: SememeRestActions::ACTION_VERSION,uuid_or_id: SememeRest::TEST_ID)
d = SememeRest::get_sememe(action: SememeRestActions::ACTION_BY_ASSEMBLAGE,uuid_or_id: SememeRest::TEST_ID)
e = SememeRest::get_sememe(action: SememeRestActions::ACTION_SEMEME_DEFINITION,uuid_or_id: SememeRest::TEST_UUID_SEMEME_DEF)
f = SememeRest::get_sememe(action: SememeRestActions::ACTION_SEMEME_TYPE,uuid_or_id: SememeRest::TEST_SEMEME_TYPE_ID)
=end

