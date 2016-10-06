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
  include ApplicationHelper, CommonController

  layout 'workflow'

  def create_workflow
    usersToken = get_user_token
    default_definition = get_default_definition
    name = params[:name]
    description = params[:description]
    body_params = {definitionId: default_definition.value, creatorNid: 12345, name:name,description:description}

    results =  WorkflowRest.get_workflow(action: WorkflowRestActions::ACTION_CREATE_WORKFLOW_PROCESS,  body_params: body_params)
    session[:workflow] = results
    render json:  results.to_json
  end

  def get_default_definition
    @default_definition =  WorkflowRest.get_workflow(action: WorkflowRestActions::ACTION_DEFAULT_DEFINITION)
  end

  def dashboard_workflow

  end
end