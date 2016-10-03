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

require './lib/isaac_rest/concept_rest'
require './lib/rails_common/roles/user_session'

module ApplicationHelper
    include UserSession

    def get_user_token
        user_session(UserSession::TOKEN)
    end

    def get_concept_metadata(id)

        coordinates_token = session[:coordinatestoken].token
        additional_req_params = {coordToken: coordinates_token}

        version = ConceptRest.get_concept(action: ConceptRestActions::ACTION_DESCRIPTIONS, uuid: id, additional_req_params: additional_req_params).first
        version ? version.text : ''
    end

    def komet_user
        user_session_defined? ? user_session(UserSession::LOGIN) : 'unknown'
    end
end
