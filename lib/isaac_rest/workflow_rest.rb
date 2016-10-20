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

module WorkflowRestActions

  ACTION_ALL_DEFINITION = :all
  ACTION_PROCESS = :process
  ACTION_HISTORY = :history
  ACTION_LOCKED = :locked
  ACTION_ACTIONS = :actions
  ACTION_AVAILABLE = :available

  ACTION_CREATE = :create
  ACTION_ADVANCE = :advance
  ACTION_LOCK = :lock
  ACTION_COMPONENT = :component

end

module WorkflowRest
  include WorkflowRestActions
  include CommonActionSyms
  extend self

  #always name the root_path ROOT_PATH!
  ROOT_PATH = ISAAC_ROOT + 'rest/1/workflow/'
  PATH_WORKFLOW_WRITE = ISAAC_ROOT + 'rest/write/1/workflow/'
  PATH_ALL_DEFINITION_WORKFLOW = ROOT_PATH + 'definition/all'
  PATH_PROCESS_WORKFLOW =  ROOT_PATH + 'process'
  PATH_HISTORY_WORKFLOW = ROOT_PATH + 'process/history'
  PATH_LOCKED_WORKFLOW = ROOT_PATH + 'process/locked'
  PATH_ACTIONS_WORKFLOW = ROOT_PATH + 'process/actions'
  PATH_AVAILABLE_WORKFLOW = ROOT_PATH + 'process/available'

  PATH_CREATE_WORKFLOW = PATH_WORKFLOW_WRITE + 'create/process/create'
  PATH_ADVANCE_WORKFLOW = PATH_WORKFLOW_WRITE + 'update/process/advance'
  PATH_LOCK_WORKFLOW = PATH_WORKFLOW_WRITE + 'update/process/lock'
  PATH_COMPONENT_WORKFLOW = PATH_WORKFLOW_WRITE + 'update/process/component'

  PARAMS_EMPTY = {}

  ACTION_CONSTANTS = {
      ACTION_ALL_DEFINITION => {
          PATH_SYM => PATH_ALL_DEFINITION_WORKFLOW,
          STARTING_PARAMS_SYM => PARAMS_EMPTY,
          CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Workflow::RestWorkflowDefinition },
      ACTION_PROCESS  => {
          PATH_SYM => PATH_PROCESS_WORKFLOW ,
          STARTING_PARAMS_SYM => PARAMS_EMPTY,
          CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Workflow::RestWorkflowProcess
      },
      ACTION_HISTORY  => {
          PATH_SYM => PATH_HISTORY_WORKFLOW ,
          STARTING_PARAMS_SYM => PARAMS_EMPTY,
          CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Workflow::RestWorkflowProcessHistory
      },
      ACTION_LOCKED  => {
          PATH_SYM => PATH_LOCKED_WORKFLOW ,
          STARTING_PARAMS_SYM => PARAMS_EMPTY,
          CLAZZ_SYM => String#Gov::Vha::Isaac::Rest::Api::Data::Wrappers::RestBoolean
      },
      ACTION_ACTIONS  => {
          PATH_SYM => PATH_ACTIONS_WORKFLOW ,
          STARTING_PARAMS_SYM => PARAMS_EMPTY,
          CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Workflow::RestWorkflowAvailableAction
      },
      ACTION_AVAILABLE  => {
          PATH_SYM => PATH_AVAILABLE_WORKFLOW,
          STARTING_PARAMS_SYM => PARAMS_EMPTY,
          CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Workflow::RestWorkflowProcessHistoriesMapEntry
      },


      ACTION_CREATE   => {
          PATH_SYM => PATH_CREATE_WORKFLOW,
          STARTING_PARAMS_SYM => PARAMS_EMPTY,
          CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api::Data::Wrappers::RestWriteResponse,
          HTTP_METHOD_KEY => HTTP_METHOD_POST,
          BODY_CLASS => Gov::Vha::Isaac::Rest::Api1::Data::Workflow::RestWorkflowProcessBaseCreate
      },
      ACTION_ADVANCE  => {
          PATH_SYM => PATH_ADVANCE_WORKFLOW,
          STARTING_PARAMS_SYM => PARAMS_EMPTY,
          CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api::Data::Wrappers::RestWriteResponse,
          HTTP_METHOD_KEY => HTTP_METHOD_PUT,
          BODY_CLASS => Gov::Vha::Isaac::Rest::Api1::Data::Workflow::RestWorkflowProcessAdvancementData
      },
      ACTION_LOCK => {
          PATH_SYM => PATH_LOCK_WORKFLOW,
          STARTING_PARAMS_SYM => PARAMS_EMPTY,
          CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api::Data::Wrappers::RestWriteResponse,
          HTTP_METHOD_KEY => HTTP_METHOD_PUT,
          BODY_CLASS => String#Gov::Vha::Isaac::Rest::Api1::Data::Workflow::RestWorkflowLockingData
      },
      ACTION_COMPONENT => {
          PATH_SYM => PATH_COMPONENT_WORKFLOW,
          STARTING_PARAMS_SYM => PARAMS_EMPTY,
          CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api::Data::Wrappers::RestWriteResponse,
          HTTP_METHOD_KEY => HTTP_METHOD_PUT,
          BODY_CLASS => String#Gov::Vha::Isaac::Rest::Api1::Data::Workflow::RestWorkflowProcessComponentSpecificationData
      }
  }

  class << self
    #attr_accessor :instance_data
  end

  class Workflow < CommonRestBase::RestBase
    include CommonRest
    register_rest(rest_module: WorkflowRest, rest_actions: WorkflowRestActions)
    # attr_accessor :uuid

    def initialize( params:, body_params:, action:, action_constants:)
      super(params: params, body_params: body_params, action: action, action_constants: action_constants)
    end

    def rest_call
      json = rest_fetch(url_string: get_url, params: get_params,body_params: body_params, raw_url: get_url)
      enunciate_json(json)
    end
  end

  def main_fetch(**hash)
    get_workflow(action: hash[:action],  additional_req_params: hash[:params], body_params: hash[:body_params])
  end

  def get_workflow(action:,  additional_req_params: nil, body_params: {})
    Workflow.new(params: additional_req_params, body_params: body_params, action: action, action_constants: ACTION_CONSTANTS).rest_call
  end
end

=begin
TODO: once all the api starts working correctly i will update this sections. Reema
load('./lib/isaac_rest/workflow_rest.rb')
a = WorkflowRest::get_workflow(action: WorkflowRestActions::ACTION_ACTIONSFORPROCESSANDUSER ,  additional_req_params: {descriptionType: 'fsn', query: 'heart'} )
b = WorkflowRest::get_workflow(action: WorkflowRestActions::ACTION_ADVANCEABLEPROCESSINFORMATION,uuid: 'cc0b2455-f546-48fa-90e8-e214cc8478d6')
c = WorkflowRest::get_workflow(action: WorkflowRestActions::ACTION_DEFINITION,uuid: 'cc0b2455-f546-48fa-90e8-e214cc8478d6')
d = WorkflowRest::get_workflow(action: WorkflowRestActions::ACTION_HISTORIESFORPROCESS,uuid: 'cc0b2455-f546-48fa-90e8-e214cc8478d6')
e = WorkflowRest::get_workflow(action: WorkflowRestActions::ACTION_ISCOMPONENTINACTIVEWORKFLOW,uuid: 'cc0b2455-f546-48fa-90e8-e214cc8478d6')
f = WorkflowRest::get_workflow(action: WorkflowRestActions::ACTION_PERMISSIONSFORDEFINITIONANDUSER,uuid: 'cc0b2455-f546-48fa-90e8-e214cc8478d6')
g = WorkflowRest::get_workflow(action: WorkflowRestActions::ACTION_PROCESS,uuid: 'cc0b2455-f546-48fa-90e8-e214cc8478d6')

#TODO - need to figure out passing editToken into write calls
#create = WorkflowRest::get_workflow(action: WorkflowRestActions::ACTION_CREATE, additional_req_params: {editToken: }, body_params: { definitionId : '...',creatorNid: 12345,name: 'workflow name',description : 'workflow description'} )
#component = WorkflowRest::get_workflow(action: WorkflowRestActions::ACTION_COMPONENT, additional_req_params: {editToken: ,  processId : '...',  componentNid : 12345,  stampSequence : 12345 })
#lock = WorkflowRest::get_workflow(action: WorkflowRestActions::ACTION_LOCK, additional_req_params: {editToken: , definitionId : '...',  userId : 12345,  role : '...'})
#advance = WorkflowRest::get_workflow(action: WorkflowRestActions::ACTION_ADVANCE, additional_req_params: {editToken: , processId : '...',  userId : 12345,  actionRequested : '...',  comment : '...' })
create = WorkflowRest::get_workflow(action: WorkflowRestActions::ACTION_CREATEWORKFLOWPROCESS, body_params: { definitionId : '...',creatorNid: 12345,name: 'workflow name',description : 'workflow description'} )
addcomponent = WorkflowRest::get_workflow(action: WorkflowRestActions::ACTION_ADDCOMPONENTTOWORKFLOW, additional_req_params: {  processId : '...',  componentNid : 12345,  stampSequence : 12345 })
addworkflowuserrole = WorkflowRest::get_workflow(action: WorkflowRestActions::ACTION_ADDWORKFLOWUSERROLE, additional_req_params:  {definitionId : '...',  userId : 12345,  role : '...'})
advanceworkflowprocess = WorkflowRest::get_workflow(action: WorkflowRestActions::ACTION_ADVANCEWORKFLOWPROCESS, additional_req_params: {  processId : '...',  userId : 12345,  actionRequested : '...',  comment : '...' })
removecomponentfromworkflow = WorkflowRest::get_workflow(action: WorkflowRestActions::ACTION_REMOVECOMPONENTFROMWORKFLOW, additional_req_params:  {  processId : '...',  componentNid : 12345,  stampSequence : 12345 })

items =  WorkflowRest.get_workflow(action: WorkflowRestActions::ACTION_AVAILABLE, ...)

=end