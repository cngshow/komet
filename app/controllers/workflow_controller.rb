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
require './lib/rails_common/util/controller_helpers'
require './lib/isaac_rest/id_apis_rest'

##
# WorkflowController -
# handles the workflow screens
class WorkflowController < ApplicationController
  include ApplicationHelper, CommonController, WorkflowRest, ConceptRest
  include Gov::Vha::Isaac::Rest::Api1::Data::Workflow

  layout 'workflow'

  def create_workflow #create workflow on success it returns processID
    default_definition = get_all_definition.first.id #this makes a call to all definition rest api and get definitionID
    name = params[:name] #populated from create workflow form and passed in from javascript file workflow.js line 82 has saveworkflow function
    description = params[:description] #populated from create workflow form and passed in from javascript file workflow.js line 82 has saveworkflow function
    additional_req_params ={editToken: get_edit_token} # have to pass it to all write rest api's
    body_params = RestWorkflowProcessBaseCreate.new
    body_params.definitionId = default_definition
    body_params.name = name
    body_params.description = description
    #code line below make a call to create work flow rest api
    results = WorkflowRest.get_workflow(action: WorkflowRestActions::ACTION_CREATE, body_params: body_params, additional_req_params: additional_req_params)

    if results.is_a? CommonRest::UnexpectedResponse
      render json: {process_id: nil} and return
    end

    process_id = results.uuid
    set_user_workflow_session({def_uuid: default_definition, process_id: process_id})
    render json: {process_id: process_id}
  end

  def get_all_definition #returns definition id. this id is passed in other rest api calls
    @default_definition = get_workflow(action: WorkflowRestActions::ACTION_ALL_DEFINITION)
  end


  def get_workflowLock
    @workflowLockState = get_workflow_details(action: WorkflowRestActions::ACTION_LOCKED)
  end

  def set_user_workflow
    set_user_workflow_session
    render json: {}
  end

  def dashboard_workflow
  end

  def get_transition
    get_workflow_details(action: WorkflowRestActions::ACTION_ACTIONS, include_token: true)
  end

  def get_process
    results = get_workflow_details_hash(action: WorkflowRestActions::ACTION_PROCESS)
    results = results.to_jaxb_json_hash
    u = ConceptRest::get_concept(action: ConceptRestActions::ACTION_DESCRIPTIONS, uuid: results['creatorId'])
    results['creatorName'] = u.first.text # todo this is pulling the first description as opposed to finding the preferred name
    render json: results.to_json
  end

  def get_history
    results = get_workflow_details_hash(action: WorkflowRestActions::ACTION_HISTORY)
    results = results.to_jaxb_json_hash

    # iterate the results getting the name for the userId from the concept description api
    results.each do |h|
      # get the user name
      u = ConceptRest::get_concept(action: ConceptRestActions::ACTION_DESCRIPTIONS, uuid: h['userId'])
      h['userName'] = u.first.text # todo this is pulling the first description as opposed to finding the preferred name
    end

    render json: results.to_json
  end

  def modal_transition_metadata
    action = params[:action_uuid]
    if (action.eql?('e47c7651-ed0d-4d0b-a12b-4d0080864a60'))
      t = "hello #{action}<br><br><label for=\"greg\">Greg</label><br><input type=\"text\" id=\"greg\" name=\"greg\" required=\"required\"\>"
    else
      t = "hello #{action}<br><br><span style=\"font-weight: bold\">nothing new here</span>"
    end
    render text: ''
    # render text: t
  end

  def get_advanceable_process_information #this method populated grid on dashboard workflow
    #todo search text box filter on top of workflowdashboard does not work has bug
    column_definitions = {}
    definition_id = get_all_definition
    additional_req_params ={definitionId: definition_id.first.id, editToken: get_edit_token}
    filter = params[:overview_sets_filter]
    page_size = 1000 #params[:overview_items_page_size]
    page_number = 1 #params[:overview_items_page_number]
    results = {column_definitions: column_definitions, page_number: page_number}
    item_data = []
    extended_columns = []
    #make call to rest api. this rest api works successfully
    # items = get_workflow_details(action: WorkflowRestActions::ACTION_AVAILABLE) # todo hash as last argument? **args = {}

    items = WorkflowRest.get_workflow(action: WorkflowRestActions::ACTION_AVAILABLE, additional_req_params: additional_req_params)

    if items.is_a? CommonRest::UnexpectedResponse
      return {total_number: 0, page_number: 1, data: []}
    end

    #this code  populates the grid on workflow dashboard
    items.each do |item|
      item_hash = {}
      item_hash[:process_id] = item.key.id
      item_hash[:name] = '<a onclick=WorkflowModule.showTaxonomy("' + item.key.id + '")>' + item.key.name + '</a>'
      item_hash[:description] = item.key.description
      item_hash[:status] = "#{item.value.last.outcomeState}<span class=\"fa fa-lock\" style=\"color: red\"></span>&nbsp;&nbsp;<span class=\"fa fa-unlock\" style=\"color: green\"></span>&nbsp;&nbsp;<a onclick=WorkflowModule.release('#{item.key.id}') class=\"fa fa-undo btn btn-sm btn-outline-primary\" aria-hidden=\"true\"></a>"
      item_hash[:viewhistory] = '<a onclick=WorkflowModule.showHistory("' + item.key.id + '")>View History</a>'
      item_hash[:viewconcept] = '<a onclick=WorkflowModule.showConcept("' + item.key.id + '")>View Concept</a>'
      item_hash[:release] = '<a onclick=WorkflowModule.release("' + item.key.id + '") class="btn btn-primary btn-sm">Release</a>'
      item_data << item_hash
    end

    results[:total_number] = items.length
    results[:data] = item_data
    render json: results
  end

  def advance_workflow
    #grab params
    comment = params[:wfl_modal_comment]
    transition_uuid = params[:transition_uuid]
    advancement = RestWorkflowProcessAdvancementData.new
    advancement.actionRequested = 'Edit'
    advancement.comment = comment
    result = WorkflowRest.get_workflow(action: WorkflowRestActions::ACTION_ADVANCE, body_params: advancement, additional_req_params: {editToken: get_edit_token, CommonRest::CacheRequest => false})
    $log.debug("Advanced: #{result}")
    clear_user_workflow
    redirect_to komet_dashboard_dashboard_path
  end

  private
  def set_user_workflow_session(args = {})
    # there is only one definition right now
    def_uuid = args.has_key?(:def_uuid) ? args[:def_uuid] : get_all_definition.first.id
    process_id = args.has_key?(:process_id) ? args[:process_id] : params[:process_id]

    if process_id
      user_session(UserSession::WORKFLOW_UUID, process_id)
      user_session(UserSession::WORKFLOW_DEF_UUID, def_uuid)
    end
  end

  def get_workflow_details_hash(action:, include_token: false)
    wfl_uuid = params[:processId] ? params[:processId] : user_session(UserSession::WORKFLOW_UUID)
    results = []

    if wfl_uuid
      additional_req_params ={processId: wfl_uuid}
      additional_req_params[:editToken] = get_edit_token if include_token
      results = WorkflowRest.get_workflow(action: action, additional_req_params: additional_req_params)
    end
    results
  end

  def get_workflow_details(action:, include_token: false)
    render json: get_workflow_details_hash(action: action, include_token: include_token).to_json
  end
end



