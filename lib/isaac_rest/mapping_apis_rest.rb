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

module MappingApiActions
    ACTION_SETS = :sets
    ACTION_ITEMS = :items
    ACTION_SET = :set
    ACTION_CREATE_SET = :create_set
    ACTION_CREATE_ITEM = :create_item
    ACTION_UPDATE_SET = :update_set
    ACTION_UPDATE_ITEM = :update_item
end

module MappingApis
    include MappingApiActions
    include CommonActionSyms
    extend self, CommonRestCallbacks

    ROOT_PATH = ISAAC_ROOT + 'rest/1/mapping/'
    PATH_MAPPING_WRITE_API = ISAAC_ROOT + 'rest/write/1/mapping/'
    PATH_SETS = ROOT_PATH + 'mappingSets'
    PATH_ITEMS = ROOT_PATH + 'mappingItems/{id}'
    PATH_SET = ROOT_PATH + 'mappingSet/{id}'
    PATH_CREATE_SET = PATH_MAPPING_WRITE_API + 'mappingSet/create'
    PATH_CREATE_ITEM = PATH_MAPPING_WRITE_API + 'mappingItem/create'
    PATH_UPDATE_SET = PATH_MAPPING_WRITE_API + 'mappingSet/update/{id}'
    PATH_UPDATE_ITEM = PATH_MAPPING_WRITE_API + 'mappingItem/update/{id}'

    # these are not used!!
    PARAMS_EMPTY = {}
    PARAMS_NO_CACHE = CommonRest::CacheRequest::PARAMS_NO_CACHE


    ACTION_CONSTANTS = {
        ACTION_SETS => {
            PATH_SYM => PATH_SETS,
            STARTING_PARAMS_SYM => PARAMS_EMPTY,
            CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Mapping::RestMappingSetVersion},
        ACTION_ITEMS => {
            PATH_SYM => PATH_ITEMS,
            STARTING_PARAMS_SYM => PARAMS_EMPTY,
            CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Mapping::RestMappingItemVersion},
        ACTION_SET => {
            PATH_SYM => PATH_SET,
            STARTING_PARAMS_SYM => PARAMS_EMPTY,
            CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Mapping::RestMappingSetVersion},
        ACTION_CREATE_SET => {
            PATH_SYM => PATH_CREATE_SET,
            STARTING_PARAMS_SYM => PARAMS_EMPTY,
            CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api::Data::Wrappers::RestWriteResponse,
            HTTP_METHOD_KEY => HTTP_METHOD_POST,
            BODY_CLASS => Gov::Vha::Isaac::Rest::Api1::Data::Mapping::RestMappingSetVersionBaseCreate},
        ACTION_CREATE_ITEM => {
            PATH_SYM => PATH_CREATE_ITEM,
            STARTING_PARAMS_SYM => PARAMS_EMPTY,
            CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api::Data::Wrappers::RestWriteResponse,
            HTTP_METHOD_KEY => HTTP_METHOD_POST,
            BODY_CLASS => Gov::Vha::Isaac::Rest::Api1::Data::Mapping::RestMappingItemVersionCreate},
        ACTION_UPDATE_SET => {
            PATH_SYM => PATH_UPDATE_SET,
            STARTING_PARAMS_SYM => PARAMS_EMPTY,
            CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api::Data::Wrappers::RestWriteResponse,
            HTTP_METHOD_KEY => HTTP_METHOD_PUT,
            BODY_CLASS => Gov::Vha::Isaac::Rest::Api1::Data::Mapping::RestMappingSetVersionBaseUpdate},
        ACTION_UPDATE_ITEM => {
            PATH_SYM => PATH_UPDATE_ITEM,
            STARTING_PARAMS_SYM => PARAMS_EMPTY,
            CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api::Data::Wrappers::RestWriteResponse,
            HTTP_METHOD_KEY => HTTP_METHOD_PUT,
            BODY_CLASS => Gov::Vha::Isaac::Rest::Api1::Data::Mapping::RestMappingItemVersionUpdate}
    }

    class << self
        #attr_accessor :instance_data
    end

    class MappingApi < CommonRestBase::RestBase
        include CommonRest
        register_rest(rest_module: MappingApis, rest_actions: MappingApiActions)

        attr_accessor :uuid

        def initialize(uuid:, action:, params:, body_params:, action_constants:)
            @uuid = uuid.to_s unless uuid.nil?
            uuid_check uuid: uuid unless [MappingApiActions::ACTION_SETS, MappingApiActions::ACTION_CREATE_SET, MappingApiActions::ACTION_CREATE_ITEM].include?(action)
            super(params: params, body_params: body_params, action: action, action_constants: action_constants)
        end

        def rest_call
            url = get_url
            url_string = uuid.nil? ? url : url.gsub('{id}', uuid)
            json = rest_fetch(url_string: url_string, params: get_params, body_params: body_params, raw_url: get_url)
            enunciate_json(json)
        end
    end

    def main_fetch(**hash)
        get_mapping_api(action: hash[:action], uuid_or_id: hash[:id], additional_req_params: hash[:params], body_params: hash[:body_params])
    end

    def get_mapping_api(action:, uuid_or_id: nil, additional_req_params: nil, body_params: {})
         MappingApi.new(action: action, uuid: uuid_or_id, params: additional_req_params, body_params: body_params, action_constants: ACTION_CONSTANTS).rest_call
    end
end

=begin
load('./lib/isaac_rest/mapping_apis_rest.rb')
#TODO - need to figure out passing editToken into write calls
#post_test = MappingApis::get_mapping_api(action: MappingApiActions::ACTION_CREATE_SET, additional_req_params: {editToken: },  body_params: {name: "Map Set Test 1", description: "The first test of creating a mapset.", purpose: "The first test of creating a mapset using the rest APIs." } )
#put_test = MappingApis::get_mapping_api(uuid_or_id: '83d0b015-ba7e-4e52-8490-0c96ba32b19b', action: MappingApiActions::ACTION_UPDATE_SET, additional_req_params: {editToken: },  body_params: {name: "Map Set Test 1.1", description: "The first test of updating a mapset.", purpose: "The first test of updating a mapset using the rest APIs." } )
get_test = MappingApis::get_mapping_api(action: MappingApiActions::ACTION_SETS,  additional_req_params: {} )
set_test = MappingApis::get_mapping_api(action: MappingApiActions::ACTION_SET, uuid_or_id: "a9262b1e-f650-5440-9d0d-edf75851ce91" )
=end

