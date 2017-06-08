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

module AssociationRestActions
    ACTION_TYPES = :types
    ACTION_TYPE = :type
    ACTION_WITH_TYPE = :with_type
    ACTION_WITH_SOURCE = :with_source
    ACTION_WITH_TARGET = :with_target
    ACTION_TYPE_CREATE = :type_create
    ACTION_ITEM_CREATE = :item_create
    ACTION_ITEM_UPDATE = :item_update
end

module AssociationRest
    include AssociationRestActions
    include CommonActionSyms
    extend self

    #always name the root_path ROOT_PATH!
    ROOT_PATH = ISAAC_ROOT + 'rest/1/association/'
    PATH_CONCEPT_WRITE = ISAAC_ROOT + 'rest/write/1/association/'

    PATH_TYPES = ROOT_PATH + 'types'
    PATH_TYPE = ROOT_PATH + 'type/{id}'
    PATH_WITH_TYPE = ROOT_PATH + 'withType/{id}'
    PATH_WITH_SOURCE = ROOT_PATH + 'withSource/{id}'
    PATH_WITH_TARGET = ROOT_PATH + 'withTarget/{id}'

    PATH_TYPE_CREATE  = PATH_CONCEPT_WRITE + 'type/create'
    PATH_ITEM_CREATE = PATH_CONCEPT_WRITE + 'item/create'
    PATH_ITEM_UPDATE = PATH_CONCEPT_WRITE + 'item/update/{id}'

    TEST_ID = '3621bf47-a54c-5f6e-a68d-c4dcb7156815'
    PARAMS_EMPTY = {}

    ACTION_CONSTANTS = {
        ACTION_TYPES => {
            PATH_SYM => PATH_TYPES,
            STARTING_PARAMS_SYM => PARAMS_EMPTY,
            CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Association::RestAssociationTypeVersion},
        ACTION_TYPE => {
            PATH_SYM => PATH_TYPE, 
            STARTING_PARAMS_SYM => PARAMS_EMPTY, 
            CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Association::RestAssociationTypeVersion},
        ACTION_WITH_TYPE => {
            PATH_SYM => PATH_WITH_TYPE, 
            STARTING_PARAMS_SYM => PARAMS_EMPTY, 
            CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Association::RestAssociationItemVersionPage},
        ACTION_WITH_SOURCE => {
            PATH_SYM => PATH_WITH_SOURCE, 
            STARTING_PARAMS_SYM => PARAMS_EMPTY, 
            CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Association::RestAssociationItemVersion},
        ACTION_WITH_TARGET => {
            PATH_SYM => PATH_WITH_TARGET, 
            STARTING_PARAMS_SYM => PARAMS_EMPTY, 
            CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Association::RestAssociationItemVersion},
        ACTION_TYPE_CREATE => {
            PATH_SYM => PATH_TYPE_CREATE ,
            STARTING_PARAMS_SYM => PARAMS_EMPTY,
            CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api::Data::Wrappers::RestWriteResponse,
            HTTP_METHOD_KEY => HTTP_METHOD_POST,
            BODY_CLASS => Gov::Vha::Isaac::Rest::Api1::Data::Association::RestAssociationTypeVersionCreate},
        ACTION_ITEM_CREATE => {
            PATH_SYM => PATH_ITEM_CREATE ,
            STARTING_PARAMS_SYM => PARAMS_EMPTY,
            CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api::Data::Wrappers::RestWriteResponse,
            HTTP_METHOD_KEY => HTTP_METHOD_POST,
            BODY_CLASS => Gov::Vha::Isaac::Rest::Api1::Data::Association::RestAssociationItemVersionCreate},
        ACTION_ITEM_UPDATE => {
            PATH_SYM => PATH_ITEM_UPDATE, 
            STARTING_PARAMS_SYM => PARAMS_EMPTY,
            CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api::Data::Wrappers::RestWriteResponse,
            HTTP_METHOD_KEY => HTTP_METHOD_PUT,
            BODY_CLASS => Gov::Vha::Isaac::Rest::Api1::Data::Association::RestAssociationItemVersionUpdate}
    }

    class << self
        #attr_accessor :instance_data
    end

    class Association < CommonRestBase::RestBase
        include CommonRest
        register_rest(rest_module: AssociationRest, rest_actions: AssociationRestActions)

        attr_accessor :uuid

        def initialize(uuid:, params:, body_params:, action:, action_constants:)
            @uuid = uuid.to_s unless uuid.nil?
            uuid_check uuid: uuid unless [AssociationRestActions::ACTION_TYPES, AssociationRestActions::ACTION_TYPE_CREATE, AssociationRestActions::ACTION_ITEM_CREATE].include?(action)
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
        get_association(action: hash[:action], uuid_or_id: hash[:id], additional_req_params: hash[:params], body_params: hash[:body_params])
    end

    def get_association(action:, uuid_or_id: nil, additional_req_params: nil, body_params: {})
        Association.new(uuid: uuid_or_id, params: additional_req_params, body_params: body_params, action: action, action_constants: ACTION_CONSTANTS).rest_call
    end
end

=begin
load('./lib/isaac_rest/association_rest.rb')
# TODO - add write tests and need to figure out passing editToken into write calls
# see intake_rest.rb on getting editToken
=end

