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

module CommentApiActions
    ACTION_VERSION = :version
    ACTION_BY_REFERENCED_COMPONENT = :by_referenced_component
    ACTION_CREATE = :create
    ACTION_UPDATE = :update
end

module CommentApis
    include CommentApiActions
    include CommonActionSyms
    extend self

    PATH_COMMENT_API = ISAAC_ROOT + 'rest/1/comment/'
    PATH_COMMENT_WRITE_API = ISAAC_ROOT + 'rest/write/1/comment/'
    PATH_VERSION = PATH_COMMENT_API + 'version/{id}'
    PATH_BY_REFERENCED_COMPONENT = PATH_COMMENT_API + 'version/byReferencedComponent/{id}'
    PATH_CREATE = PATH_COMMENT_WRITE_API + 'create'
    PATH_UPDATE = PATH_COMMENT_WRITE_API + 'update'

    # these are not used!!
    PARAMS_EMPTY = {}

    ACTION_CONSTANTS = {
        ACTION_VERSION => {
            PATH_SYM => PATH_VERSION,
            STARTING_PARAMS_SYM => PARAMS_EMPTY,
            CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Comment::RestCommentVersion},
        ACTION_BY_REFERENCED_COMPONENT => {
            PATH_SYM => PATH_BY_REFERENCED_COMPONENT,
            STARTING_PARAMS_SYM => PARAMS_EMPTY,
            CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Comment::RestCommentVersion},
        ACTION_CREATE => {
            PATH_SYM => PATH_CREATE,
            STARTING_PARAMS_SYM => PARAMS_EMPTY,
            CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api::Data::Wrappers::RestInteger,
            HTTP_METHOD_KEY => HTTP_METHOD_POST,
            BODY_CLASS => Gov::Vha::Isaac::Rest::Api1::Data::Comment::RestCommentVersionBaseCreate},
        ACTION_UPDATE => {
            PATH_SYM => PATH_UPDATE,
            STARTING_PARAMS_SYM => PARAMS_EMPTY,
            CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api::Data::Wrappers::RestInteger,
            HTTP_METHOD_KEY => HTTP_METHOD_PUT,
            BODY_CLASS => Gov::Vha::Isaac::Rest::Api1::Data::Comment::RestCommentVersionBase},
    }

    class << self
        #attr_accessor :instance_data
    end

    class CommentApi < CommonRestBase::RestBase
        include CommonRest
        register_rest(rest_module: CommentApis, rest_actions: CommentApiActions)

        attr_accessor :uuid

        def initialize(uuid:, action:, params:, body_params:, action_constants:)
            @uuid = uuid.to_s unless uuid.nil?
            uuid_check uuid: uuid unless [CommentApiActions::ACTION_CREATE, CommentApiActions::ACTION_UPDATE].include?(action)
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
        get_comment_api(action: hash[:action], uuid_or_id: hash[:id], additional_req_params: hash[:params], body_params: hash[:body_params])
    end

    def get_comment_api(action:, uuid_or_id: nil, additional_req_params: nil, body_params: {})
         CommentApi.new(action: action, uuid: uuid_or_id, params: additional_req_params, body_params: body_params, action_constants: ACTION_CONSTANTS).rest_call
    end
end

=begin
load('./lib/isaac_rest/comment_apis_rest.rb')
{commentedItem: '614592', comment: 'Comment 1', commentContext: 'context?'}
post_test = CommentApis::get_comment_api(action: CommentApiActions::ACTION_CREATE,  body_params: {commentedItem: '614592', comment: 'Comment 2', commentContext: 'context?'} )
put_test = CommentApis::get_comment_api(action: CommentApiActions::ACTION_UPDATE, additional_req_params: {state: 'INACTIVE', id: '27ec9a64-be83-4ef4-8bc2-a5e279b4d5f8'},  body_params: {comment: 'Comment 1.1', commentContext: 'context?'} )
get_test = CommentApis::get_comment_api(uuid_or_id: '669c79b6-f977-4284-8594-a45673cedb6b', action: CommentApiActions::ACTION_BY_REFERENCED_COMPONENT,  additional_req_params: {} )
=end

