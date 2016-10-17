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
#WorkflowController -
# handles the workflow screens
class WorkflowController < ApplicationController
  include ApplicationHelper, CommonController, WorkflowRest

  layout 'workflow'

  def create_workflow  #create workflow on success it returns processID
    default_definition = get_all_definition #this make a call to all definition rest api and get definitionID
    name = params[:name] #populated from create workflow form and passed in from javascript file workflow.js line 82 has saveworkflow function
    description = params[:description]#populated from create workflow form and passed in from javascript file workflow.js line 82 has saveworkflow function
    additional_req_params ={editToken: get_edit_token} # have to pass it to all write rest api's
    body_params = {definitionId:default_definition[0].value, name:name,description:description} #create workflow requires body params
    #code line below make a call to create work flow rest api
    results =  WorkflowRest.get_workflow(action: WorkflowRestActions::ACTION_CREATE,  body_params: body_params,additional_req_params:additional_req_params)

    if results.is_a? CommonRest::UnexpectedResponse
      render json: {process_id: nil} and return
    end

    render json: {process_id: results.uuid}   #create workflow on success it returns processID
  end

  def get_all_definition #returns definition id. this id is passed in other rest api calls.  this rest api works successfully
    @default_definition =  WorkflowRest.get_workflow(action: WorkflowRestActions::ACTION_ALL_DEFINITION)
  end


   def get_workflowLock #todo  rest api code from yesterday  10/13 has a bug. joel working on resolving error on dated 10/14
     process_id = params[:processId]
     additional_req_params ={processId:params[:processId] }
     @workflowLockState =  WorkflowRest.get_workflow(action: WorkflowRestActions::ACTION_LOCKED,  additional_req_params: additional_req_params)
   end

  def dashboard_workflow

  end

  def get_transition  #based on old rest api naming i named method get transtion. all new changes in rest api this is now called action instead of transition
    process_id = params[:processId]
    additional_req_params ={processId:process_id ,editToken: get_edit_token}
    transition =  WorkflowRest.get_workflow(action: WorkflowRestActions::ACTION_ACTIONS,  additional_req_params: additional_req_params)
    render json:  transition.to_json
  end

  def get_process  #based on processID #todo rest api code from yesterday  10/13 has a bug. joel working on resolving error on dated 10/14
   additional_req_params ={processId:params[:processId] }
    workflow_set =  WorkflowRest.get_workflow(action: WorkflowRestActions::ACTION_PROCESS,  additional_req_params: additional_req_params)
    render json:  workflow_set.to_json
  end

def  get_history #based on processID  #todo  rest api code from yesterday  10/13 has a bug. joel working on resolving error on dated 10/14
  process_id = params[:processId]
  additional_req_params ={processId:process_id}
  historiesforprocess =  WorkflowRest.get_workflow(action: WorkflowRestActions::ACTION_HISTORY,  additional_req_params: additional_req_params)
  render json:  historiesforprocess.to_json
end


def get_advanceable_process_information #this method populated grid on dashboard workflow
  #todo search text box filter on top of workflowdashboard does not work has bug
  column_definitions = {}
  definition_id = get_all_definition
  additional_req_params ={definitionId:definition_id[0].value ,editToken: get_edit_token}
  filter = params[:overview_sets_filter]
  page_size = 1000 #params[:overview_items_page_size]
  page_number = 1 #params[:overview_items_page_number]
  results = {column_definitions: column_definitions, page_number: page_number}
  item_data = []
  extended_columns = []
  #make call to rest api. this rest api works successfully
  items =  WorkflowRest.get_workflow(action: WorkflowRestActions::ACTION_AVAILABLE,  additional_req_params: additional_req_params)

  if items.is_a? CommonRest::UnexpectedResponse
    return {total_number: 0, page_number: 1, data: []}
  end

  items.each do |item|  #this code  populates the grid on workflow dashboar

    item_hash = {}
    item_hash[:process_id] = item.key.id
    item_hash[:name] = '<a  onclick=WorkflowModule.showTaxaonomy("' + item.key.id + '")>' + item.key.name + '</a>'
    item_hash[:description] = item.key.description
    item_hash[:status] = item.key.processStatus.name
    item_hash[:viewhistory] =  '<a   onclick=WorkflowModule.showHistroy("' + item.key.id + '")>View History</a>'
    item_hash[:viewconcept] = '<a onclick=WorkflowModule.showConcept("' + item.key.id + '")>View Concept</a>'
    item_data << item_hash
  end

  results[:total_number] = items.length

 # matching_items = session['work_item_data'].select { |item|
  #  item[:set_id] == set_id.to_s
  #}

  results[:data] = item_data
  render json: results
end


end



