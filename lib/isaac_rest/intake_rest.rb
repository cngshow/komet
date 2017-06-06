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

module IntakeRestActions
  ACTION_VETS_XML = :vets_xml
end

module IntakeRest
  include IntakeRestActions
  include CommonActionSyms
  extend self, CommonRestCallbacks

  #always name the root_path ROOT_PATH!
  ROOT_PATH = ISAAC_ROOT + 'rest/write/1/intake/'
  PATH_VETS_XML_INTAKE = ROOT_PATH + 'vetsXML'

  PARAMS_EMPTY = {}

  ACTION_CONSTANTS = {
    ACTION_VETS_XML => {
      PATH_SYM => PATH_VETS_XML_INTAKE,
      STARTING_PARAMS_SYM => PARAMS_EMPTY,
      CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api::Data::Wrappers::RestWriteResponse,
      HTTP_METHOD_KEY => HTTP_METHOD_POST,
      BODY_CLASS => String,
      CALLBACKS => [IntakeRest.clear_lambda]
    }
  }

  #main_fetch is only needed for get requests, For example:
  #CommonRestBase::RestBase.invoke(url: "/rest/1/concept/version/5/")
  #will call your impl of main_fetch
  # def main_fetch(**hash)
  #   get_intake(action: hash[:action], body_params: hash[:body_params], additional_req_params: hash[:params])
  # end

  def get_intake(action:, body_string:, additional_req_params: nil)
      Intake.new(params: additional_req_params, body_string: body_string, action: action, action_constants: ACTION_CONSTANTS).rest_call
  end
end

class IntakeRest::Intake < CommonRestBase::RestBase
  include CommonRest
  #register_rest(rest_module: IntakeRest, rest_actions: IntakeRestActions)#We only need to register 'get' based apis.

  def initialize(body_string:, action:, action_constants:, params:)
    super(body_string: body_string, action: action, action_constants: action_constants, params: params)
  end

  def rest_call
    rest_fetch(enunciate: false, url_string: get_url, params: get_params, body_string: body_string, raw_url: get_url,  content_type: 'application/xml')
  end
end

=begin
      load('./lib/isaac_rest/intake_rest.rb')
      load './lib/roles_test/roles.rb'
      user_info = RolesTest::user_roles(user: 'devtest', password: 'devtest')
      token = user_info['token']
      b = CoordinateRest.get_coordinate(action: CoordinateRestActions::ACTION_EDIT_TOKEN, additional_req_params: {ssoToken: token, CommonRest::CacheRequest => false}).token
      additional_req_params ={editToken: b}

  result = IntakeRest::get_intake(action: IntakeRest::ACTION_VETS_XML, body_string: '<xml><cris>is cool</cris></xml>', additional_req_params: additional_req_params)

=end