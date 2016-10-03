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

  ACTION_ACTIONS_FOR_PROCESS_AND_USER = :actionsForProcessAndUser
  ACTION_ADVANCEABLE_PROCESS_INFORMATION= :advanceableProcessInformation
 # ACTION_DEFAULT_DEFINITION = :defaultDefinition
  #ACTION_AVAILABLE_DEFINITION = :availableDefinitions
  ACTION_HISTORIES_FOR_PROCESS = :historiesForProcess

  ACTION_PERMISSIONS_FOR_DEFINITION_AND_USER = :permissionsForDefinitionAndUser
  ACTION_PROCESS = :process
  ACTION_CREATE_WORKFLOW_PROCESS = :createWorkflowProcess
  ACTION_ADVANCE_WORKFLOW_PROCESS = :advanceWorkflowProcess
  ACTION_REMOVE_COMPONENT_FROM_WORKFLOW = :removeComponentFromWorkflow

end

module WorkflowRest
  include WorkflowRestActions
  include CommonActionSyms
  extend self

  #always name the root_path ROOT_PATH!
  ROOT_PATH = ISAAC_ROOT + 'rest/1/workflow/'
  PATH_WORKFLOW_WRITE = ISAAC_ROOT + 'rest/write/1/workflow/1/workflow/'
  PATH_ACTION_ACTIONS_FOR_PROCESS_AND_USER_WORKFLOW = ROOT_PATH + 'actionsForProcessAndUser'
  PATH_ADVANCEABLE_PROCESS_INFORMATION_WORKFLOW =  ROOT_PATH + 'advanceableProcessInformation'
 # PATH_DEFAULT_DEFINITION_WORKFLOW = ROOT_PATH + 'defaultDefinition'
  #PATH_AVAILABLE_DEFINITION_WORKFLOW = ROOT_PATH + 'availableDefinitions'
  PATH_HISTORIES_FOR_PROCESS_WORKFLOW =  ROOT_PATH + 'historiesForProcess'

  PATH_PERMISSIONS_FOR_DEFINITION_AND_USER_WORKFLOW =  ROOT_PATH + 'permissionsForDefinitionAndUser'
  PATH_PROCESS_WORKFLOW =  ROOT_PATH + 'process'
  PATH_CREATE_WORKFLOW_PROCESS_WORKFLOW = PATH_WORKFLOW_WRITE + 'create/createWorkflowProcess'
  PATH_ADVANCE_WORKFLOW_PROCESS_WORKFLOW = PATH_WORKFLOW_WRITE + 'update/advanceWorkflowProcess'
  PATH_REMOVE_COMPONENT_FROM_WORKFLOW = PATH_WORKFLOW_WRITE + 'update/removeComponentFromWorkflow'

  PARAMS_EMPTY = {}

  ACTION_CONSTANTS = {
      ACTION_ACTIONS_FOR_PROCESS_AND_USER => {
          PATH_SYM => PATH_ACTION_ACTIONS_FOR_PROCESS_AND_USER_WORKFLOW,
          STARTING_PARAMS_SYM => PARAMS_EMPTY,
          CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Workflow::RestWorkflowAvailableActions },
      ACTION_ADVANCEABLE_PROCESS_INFORMATION  => {
          PATH_SYM => PATH_ADVANCEABLE_PROCESS_INFORMATION_WORKFLOW,
          STARTING_PARAMS_SYM => PARAMS_EMPTY,
          CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Workflow::RestWorkflowProcessHistoriesMap
      },

      ACTION_HISTORIES_FOR_PROCESS  => {
          PATH_SYM => PATH_HISTORIES_FOR_PROCESS_WORKFLOW,
          STARTING_PARAMS_SYM => PARAMS_EMPTY,
          CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Workflow::RestWorkflowProcessHistories
      },

      ACTION_PROCESS  => {
          PATH_SYM => PATH_PROCESS_WORKFLOW,
          STARTING_PARAMS_SYM => PARAMS_EMPTY,
          CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Workflow::RestWorkflowProcess
      },

      ACTION_CREATE_WORKFLOW_PROCESS   => {
          PATH_SYM => PATH_CREATE_WORKFLOW_PROCESS_WORKFLOW,
          STARTING_PARAMS_SYM => PARAMS_EMPTY,
          CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api::Data::Wrappers::RestInteger,
          HTTP_METHOD_KEY => HTTP_METHOD_POST,
          BODY_CLASS => Gov::Vha::Isaac::Rest::Api1::Data::Workflow::RestWorkflowProcessBaseCreate
      },
      ACTION_ADVANCE_WORKFLOW_PROCESS  => {
          PATH_SYM => PATH_ADVANCE_WORKFLOW_PROCESS_WORKFLOW,
          STARTING_PARAMS_SYM => PARAMS_EMPTY,
          CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api::Data::Wrappers::RestInteger,
          HTTP_METHOD_KEY => HTTP_METHOD_PUT
      },
      ACTION_REMOVE_COMPONENT_FROM_WORKFLOW => {
          PATH_SYM => PATH_REMOVE_COMPONENT_FROM_WORKFLOW,
          STARTING_PARAMS_SYM => PARAMS_EMPTY,
          CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api::Data::Wrappers::RestInteger,
          HTTP_METHOD_KEY => HTTP_METHOD_PUT
      },
  }

  class << self
    #attr_accessor :instance_data
  end

  class Workflow < CommonRestBase::RestBase
    include CommonRest
    register_rest(rest_module: WorkflowRest, rest_actions: WorkflowRestActions)
    attr_accessor :uuid

    def initialize(uuid:, params:, body_params:, action:, action_constants:)
      @uuid = uuid.to_s unless uuid.nil?
      uuid_check uuid: uuid unless [WorkflowRestActions::ACTION_CREATE].include?(action)
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
    get_workflow(action: hash[:action], uuid: hash[:id], additional_req_params: hash[:params], body_params: hash[:body_params])
  end

  def get_workflow(action:, uuid: nil, additional_req_params: nil, body_params: {})
    Workflow.new(uuid: uuid, params: additional_req_params, body_params: body_params, action: action, action_constants: ACTION_CONSTANTS).rest_call
  end
end

=begin
load('./lib/isaac_rest/workflow_rest.rb')
a = WorkflowRest::get_workflow(action: WorkflowRestActions::ACTION_ACTIONSFORPROCESSANDUSER ,  additional_req_params: {descriptionType: 'fsn', query: 'heart'} )
b = WorkflowRest::get_workflow(action: WorkflowRestActions::ACTION_ADVANCEABLEPROCESSINFORMATION,uuid: 'cc0b2455-f546-48fa-90e8-e214cc8478d6')
c = WorkflowRest::get_workflow(action: WorkflowRestActions::ACTION_DEFINITION,uuid: 'cc0b2455-f546-48fa-90e8-e214cc8478d6')
d = WorkflowRest::get_workflow(action: WorkflowRestActions::ACTION_HISTORIESFORPROCESS,uuid: 'cc0b2455-f546-48fa-90e8-e214cc8478d6')
e = WorkflowRest::get_workflow(action: WorkflowRestActions::ACTION_ISCOMPONENTINACTIVEWORKFLOW,uuid: 'cc0b2455-f546-48fa-90e8-e214cc8478d6')
f = WorkflowRest::get_workflow(action: WorkflowRestActions::ACTION_PERMISSIONSFORDEFINITIONANDUSER,uuid: 'cc0b2455-f546-48fa-90e8-e214cc8478d6')
g = WorkflowRest::get_workflow(action: WorkflowRestActions::ACTION_PROCESS,uuid: 'cc0b2455-f546-48fa-90e8-e214cc8478d6')

create = WorkflowRest::get_workflow(action: WorkflowRestActions::ACTION_CREATEWORKFLOWPROCESS, body_params: { definitionId : '...',creatorNid: 12345,name: 'workflow name',description : 'workflow description'} )
addcomponent = WorkflowRest::get_workflow(action: WorkflowRestActions::ACTION_ADDCOMPONENTTOWORKFLOW, additional_req_params: {  processId : '...',  componentNid : 12345,  stampSequence : 12345 })
addworkflowuserrole = WorkflowRest::get_workflow(action: WorkflowRestActions::ACTION_ADDWORKFLOWUSERROLE, additional_req_params:  {definitionId : '...',  userId : 12345,  role : '...'})
advanceworkflowprocess = WorkflowRest::get_workflow(action: WorkflowRestActions::ACTION_ADVANCEWORKFLOWPROCESS, additional_req_params: {  processId : '...',  userId : 12345,  actionRequested : '...',  comment : '...' })
removecomponentfromworkflow = WorkflowRest::get_workflow(action: WorkflowRestActions::ACTION_REMOVECOMPONENTFROMWORKFLOW, additional_req_params:  {  processId : '...',  componentNid : 12345,  stampSequence : 12345 })



=end