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

module SystemApiActions
  ACTION_DYNAMIC_SEMEME_VALIDATOR_TYPE = :dynamic_sememe_validator_type
  ACTION_OBJECT_CHRONOLOGY_TYPE = :object_chronology_type
  ACTION_SEMEME_TYPE = :sememe_type
  ACTION_DYNAMIC_SEMEME_DATA_TYPE = :dynamic_sememe_data_type
  ACTION_CONCRETE_DOMAIN_OPERATOR_TYPES = :concrete_domain_operator_types
  ACTION_NODE_SEMANTIC_TYPE = :node_semantic_type
  ACTION_SUPPORTED_ID_TYPES = :supported_id_types
  ACTION_OBJECT_CHRONOLOGY_TYPE_BY_ID = :object_chronology_type_by_id
  ACTION_EXTENDED_DESCRIPTION_TYPES = :extended_description_types
  ACTION_TERMINOLOGY_TYPES = :terminology_types
  ACTION_SYSTEM_INFO = :system_info
end

module SystemApis
  include SystemApiActions
  include CommonActionSyms
  extend self

  TEST_UUID = '406e872b-2e19-5f5e-a71d-e4e4b2c68fe5'

  #always name the root_path ROOT_PATH!
  ROOT_PATH = ISAAC_ROOT + "rest/1/system/"

  PATH_OBJECT_CHRONOLOGY_TYPE_BY_ID = ROOT_PATH + "objectChronologyType/{id}"
  PATH_EXTENDED_DESCRIPTION_TYPES = ROOT_PATH + "extendedDescriptionTypes/{id}"
  PATH_TERMINOLOGY_TYPES = ROOT_PATH + "terminologyTypes"
  PATH_SYSTEM_INFO = ROOT_PATH + "systemInfo"

  PATH_SYSTEM_API_ENUMERATION =ROOT_PATH + "enumeration/"
  PATH_DYNAMIC_SEMEME_VALIDATOR_TYPE = PATH_SYSTEM_API_ENUMERATION + "restDynamicSememeValidatorType"
  PATH_OBJECT_CHRONOLOGY_TYPE = PATH_SYSTEM_API_ENUMERATION + "restObjectChronologyType"
  PATH_SEMEME_TYPE = PATH_SYSTEM_API_ENUMERATION + "restSememeType"
  PATH_DYNAMIC_SEMEME_DATA_TYPE = PATH_SYSTEM_API_ENUMERATION + "restDynamicSememeDataType"
  PATH_CONCRETE_DOMAIN_OPERATOR_TYPES = PATH_SYSTEM_API_ENUMERATION + "restConcreteDomainOperatorTypes"
  PATH_NODE_SEMANTIC_TYPE = PATH_SYSTEM_API_ENUMERATION + "restNodeSemanticType"
  PATH_SUPPORTED_ID_TYPES = PATH_SYSTEM_API_ENUMERATION + "restSupportedIdTypes"

  PARAMS_EMPTY = {}

  ACTION_CONSTANTS = {
      ACTION_DYNAMIC_SEMEME_VALIDATOR_TYPE => {
          PATH_SYM => PATH_DYNAMIC_SEMEME_VALIDATOR_TYPE,
          STARTING_PARAMS_SYM => PARAMS_EMPTY,
          CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Enumerations::RestDynamicSememeValidatorType},
      ACTION_OBJECT_CHRONOLOGY_TYPE => {
          PATH_SYM => PATH_OBJECT_CHRONOLOGY_TYPE,
          STARTING_PARAMS_SYM => PARAMS_EMPTY,
          CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Enumerations::RestObjectChronologyType},
      ACTION_SEMEME_TYPE => {
          PATH_SYM => PATH_SEMEME_TYPE,
          STARTING_PARAMS_SYM => PARAMS_EMPTY,
          CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Enumerations::RestSememeType},
      ACTION_DYNAMIC_SEMEME_DATA_TYPE => {
          PATH_SYM => PATH_DYNAMIC_SEMEME_DATA_TYPE,
          STARTING_PARAMS_SYM => PARAMS_EMPTY,
          CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Enumerations::RestDynamicSememeDataType},
      ACTION_CONCRETE_DOMAIN_OPERATOR_TYPES => {
          PATH_SYM => PATH_CONCRETE_DOMAIN_OPERATOR_TYPES,
          STARTING_PARAMS_SYM => PARAMS_EMPTY,
          CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Enumerations::RestConcreteDomainOperatorsType},
      ACTION_NODE_SEMANTIC_TYPE => {
          PATH_SYM => PATH_NODE_SEMANTIC_TYPE,
          STARTING_PARAMS_SYM => PARAMS_EMPTY,
          CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Enumerations::RestNodeSemanticType},
      ACTION_SUPPORTED_ID_TYPES => {
          PATH_SYM => PATH_SUPPORTED_ID_TYPES,
          STARTING_PARAMS_SYM => PARAMS_EMPTY,
          CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Enumerations::RestSupportedIdType},
      ACTION_OBJECT_CHRONOLOGY_TYPE_BY_ID => {
          PATH_SYM => PATH_OBJECT_CHRONOLOGY_TYPE_BY_ID,
          STARTING_PARAMS_SYM => PARAMS_EMPTY,
          CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Enumerations::RestObjectChronologyType},
      ACTION_EXTENDED_DESCRIPTION_TYPES => {
          PATH_SYM => PATH_EXTENDED_DESCRIPTION_TYPES,
          STARTING_PARAMS_SYM => PARAMS_EMPTY,
          CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Enumerations::RestObjectChronologyType},
      ACTION_TERMINOLOGY_TYPES => {
          PATH_SYM => PATH_TERMINOLOGY_TYPES,
          STARTING_PARAMS_SYM => PARAMS_EMPTY,
          CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Concept::RestTerminologyConcept},
      ACTION_SYSTEM_INFO => {
          PATH_SYM => PATH_SYSTEM_INFO,
          STARTING_PARAMS_SYM => PARAMS_EMPTY,
          CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::RestSystemInfo},
  }

  class << self
    #attr_accessor :instance_data
  end

  class SystemApi < CommonRestBase::RestBase
    include CommonRest
    register_rest(rest_module: SystemApis, rest_actions: SystemApiActions)

    attr_accessor :uuid

    def initialize(uuid: nil, action:, params: {}, action_constants:)
      @uuid = uuid.to_s unless uuid.nil?

      if [SystemApiActions::ACTION_OBJECT_CHRONOLOGY_TYPE_BY_ID, SystemApiActions::ACTION_EXTENDED_DESCRIPTION_TYPES].include?(action)
        uuid_check uuid: uuid
      end

      super(params: params, action: action, action_constants: action_constants)
    end

    def rest_call
      url = get_url
      url_string = url.gsub('{id}', uuid.to_s)
      json = rest_fetch(url_string: url_string, params: get_params, raw_url: get_url)
      enunciate_json(json)
    end
  end

  def main_fetch(**hash)
    get_system_api(action: hash[:action])
  end


  def get_system_api(action:, uuid_or_id: nil, additional_req_params: nil)
    SystemApi.new(action: action, uuid: uuid_or_id, params: additional_req_params, action_constants: ACTION_CONSTANTS).rest_call
  end
end

=begin
load('./lib/isaac_rest/system_apis_rest.rb')

a = SystemApis::get_system_api(action: SystemApiActions::ACTION_DYNAMIC_SEMEME_VALIDATOR_TYPE)
b = SystemApis::get_system_api(action: SystemApiActions::ACTION_OBJECT_CHRONOLOGY_TYPE)
c = SystemApis::get_system_api(action: SystemApiActions::ACTION_SEMEME_TYPE)
d = SystemApis::get_system_api(action: SystemApiActions::ACTION_DYNAMIC_SEMEME_DATA_TYPE)
e = SystemApis::get_system_api(action: SystemApiActions::ACTION_CONCRETE_DOMAIN_OPERATOR_TYPES)
f = SystemApis::get_system_api(action: SystemApiActions::ACTION_NODE_SEMANTIC_TYPE)
g = SystemApis::get_system_api(action: SystemApiActions::ACTION_SUPPORTED_ID_TYPES)
h = SystemApis::get_system_api(action: SystemApiActions::ACTION_OBJECT_CHRONOLOGY_TYPE_BY_ID, uuid_or_id: SystemApis::TEST_UUID)
i = SystemApis::get_system_api(action: SystemApiActions::ACTION_SYSTEM_INFO)
j = SystemApis::get_system_api(action: SystemApiActions::ACTION_EXTENDED_DESCRIPTION_TYPES, uuid_or_id: SystemApis::TEST_UUID)
k = SystemApis::get_system_api(action: SystemApiActions::TERMINOLOGY_TYPES)
=end
