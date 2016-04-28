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
  ACTION_SYSTEM_INFO = :system_info
end

module SystemApis
  include SystemApiActions
  include CommonActionSyms
  extend self

  PATH_SYSTEM_API = $PROPS['ENDPOINT.isaac_root'] + "rest/1/system/"
  PATH_SYSTEM_API_ENUMERATION =PATH_SYSTEM_API + "enumeration/"
  PATH_DYNAMIC_SEMEME_VALIDATOR_TYPE = PATH_SYSTEM_API_ENUMERATION + "restDynamicSememeValidatorType"
  PATH_OBJECT_CHRONOLOGY_TYPE = PATH_SYSTEM_API_ENUMERATION + "restObjectChronologyType"
  PATH_SEMEME_TYPE = PATH_SYSTEM_API_ENUMERATION + "restSememeType"
  PATH_DYNAMIC_SEMEME_DATA_TYPE = PATH_SYSTEM_API_ENUMERATION + "restDynamicSememeDataType"

  PATH_CONCRETE_DOMAIN_OPERATOR_TYPES = PATH_SYSTEM_API_ENUMERATION + "restConcreteDomainOperatorTypes"
  PATH_NODE_SEMANTIC_TYPE = PATH_SYSTEM_API_ENUMERATION + "restNodeSemanticType"
  PATH_SUPPORTED_ID_TYPES = PATH_SYSTEM_API_ENUMERATION + "restSupportedIdTypes"
  PATH_OBJECT_CHRONOLOGY_TYPE_BY_ID = PATH_SYSTEM_API + "objectChronologyType/{id}"
  PATH_SYSTEM_INFO = PATH_SYSTEM_API + "systemInfo"

  # these are not used!!
  PARAMS_DYNAMIC_SEMEME_VALIDATOR_TYPE = {}
  PARAMS_OBJECT_CHRONOLOGY_TYPE = {}
  PARAMS_SEMEME_TYPE = {}
  PARAMS_DYNAMIC_SEMEME_DATA_TYPE = {}

  PARAMS_CONCRETE_DOMAIN_OPERATOR_TYPES = {}
  PARAMS_NODE_SEMANTIC_TYPE = {}
  PARAMS_SUPPORTED_ID_TYPES = {}
  PARAMS_OBJECT_CHRONOLOGY_TYPE_BY_ID = {}
  PARAMS_DYNAMIC_SEMEME_DATA_TYPE = {}

  ACTION_CONSTANTS = {
      ACTION_DYNAMIC_SEMEME_VALIDATOR_TYPE => {
          PATH_SYM => PATH_DYNAMIC_SEMEME_VALIDATOR_TYPE,
          STARTING_PARAMS_SYM => PARAMS_DYNAMIC_SEMEME_VALIDATOR_TYPE,
          CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Enumerations::RestDynamicSememeValidatorType},
      ACTION_OBJECT_CHRONOLOGY_TYPE => {
          PATH_SYM => PATH_OBJECT_CHRONOLOGY_TYPE,
          STARTING_PARAMS_SYM => PARAMS_OBJECT_CHRONOLOGY_TYPE,
          CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Enumerations::RestObjectChronologyType},
      ACTION_SEMEME_TYPE => {
          PATH_SYM => PATH_SEMEME_TYPE,
          STARTING_PARAMS_SYM => PARAMS_SEMEME_TYPE,
          CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Enumerations::RestSememeType},
      ACTION_DYNAMIC_SEMEME_DATA_TYPE => {
          PATH_SYM => PATH_DYNAMIC_SEMEME_DATA_TYPE,
          STARTING_PARAMS_SYM => PARAMS_DYNAMIC_SEMEME_DATA_TYPE,
          CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Enumerations::RestDynamicSememeDataType},
  }

  class << self
    #attr_accessor :instance_data
  end

  class SystemApi < CommonRestBase::RestBase
    include CommonRest
    register_rest(rest_module: SystemApis, rest_actions: SystemApiActions)

    def initialize(action:, action_constants:)
      super(params: {}, action: action, action_constants: action_constants)
    end

    def rest_call
      json = rest_fetch(url_string: get_url, params: get_params, raw_url: get_url)
      enunciate_json(json)
    end
  end

  def main_fetch(**hash)
    get_system_api(action: hash[:action])
  end


  def get_system_api(action:)
    SystemApi.new(action: action, action_constants: ACTION_CONSTANTS).rest_call
  end
end

=begin
load('./lib/isaac_rest/system_apis_rest.rb')

a = SystemApis::get_system_api(action: SystemApiActions::ACTION_DYNAMIC_SEMEME_VALIDATOR_TYPE)
b = SystemApis::get_system_api(action: SystemApiActions::ACTION_OBJECT_CHRONOLOGY_TYPE)
c = SystemApis::get_system_api(action: SystemApiActions::ACTION_SEMEME_TYPE)
d = SystemApis::get_system_api(action: SystemApiActions::ACTION_DYNAMIC_SEMEME_DATA_TYPE)

=end
