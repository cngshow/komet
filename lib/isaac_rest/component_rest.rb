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

module ComponentRestActions
    ACTION_UPDATE_STATE = :update_state
end

module ComponentRest
    include ComponentRestActions
    include CommonActionSyms
    extend self
    
    PATH_COMPONENT_WRITE_API = ISAAC_ROOT + 'rest/write/component/'
    PATH_UPDATE_STATE = PATH_COMPONENT_WRITE_API + 'update/state/{id}'
    
    PARAMS_EMPTY = {}

    ACTION_CONSTANTS = {
        ACTION_UPDATE_STATE => {
            PATH_SYM => PATH_UPDATE_STATE,
            STARTING_PARAMS_SYM => PARAMS_EMPTY,
            CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api::Data::Wrappers::RestWriteResponse,
            HTTP_METHOD_KEY => HTTP_METHOD_PUT}
    }

    class << self
        #attr_accessor :instance_data
    end

    class Component < CommonRestBase::RestBase
        include CommonRest
        register_rest(rest_module: ComponentRest, rest_actions: ComponentRestActions)

        attr_accessor :uuid

        def initialize(uuid:, action:, params:, body_params:, action_constants:)
            @uuid = uuid.to_s unless uuid.nil?
            uuid_check uuid: uuid # unless [].include?(action)
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
        get_component(action: hash[:action], uuid_or_id: hash[:id], additional_req_params: hash[:params], body_params: hash[:body_params])
    end

    def get_component(action:, uuid_or_id: nil, additional_req_params: nil, body_params: {})
         Component.new(action: action, uuid: uuid_or_id, params: additional_req_params, body_params: body_params, action_constants: ACTION_CONSTANTS).rest_call
    end
end

=begin
load('./lib/isaac_rest/component_rest.rb')
#TODO - need to figure out passing editToken into write calls
#update_state = ComponentRest::get_component(action: ComponentRestActions::ACTION_UPDATE_STATE, additional_req_params: {editToken: , id: 'f66bc690-1bcd-513a-8b42-350465c2bf47', active: false} )
=end

