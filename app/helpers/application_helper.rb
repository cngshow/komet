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
require './lib/isaac_rest/coordinate_rest'
require './lib/rails_common/roles/user_session'

module ApplicationHelper
  include UserSession
  include BootstrapNotifier


  def get_user_token
    user_session(UserSession::TOKEN)
  end

  def get_concept_metadata(id)

    coordinates_token = session[:coordinatestoken].token
    additional_req_params = {coordToken: coordinates_token}

    version = ConceptRest.get_concept(action: ConceptRestActions::ACTION_DESCRIPTIONS, uuid: id, additional_req_params: additional_req_params)

    if version.is_a? CommonRest::UnexpectedResponse
      return ''
    else
      return version.first.text
    end
  end

  def get_edit_token
    CoordinateRest.get_coordinate(action: CoordinateRestActions::ACTION_EDIT_TOKEN, additional_req_params: {ssoToken: get_user_token, CommonRest::CacheRequest => false}).token
  end

  def komet_user
    user_session_defined? ? user_session(UserSession::LOGIN) : 'unknown'
  end

  def redirect_to_proxy_sensitive(url_string)
    if ssoi? #if we are under ssoi we assume we are behind apache
      redirect_to PrismeConfigConcern.recontext(url_string: url_string, controller: my_controller)
    else
      redirect_to url_string
    end
  end

  def proxy_sensitive(url_string)
    url_string = url_string.to_s
    host = my_controller.true_address
    port = my_controller.true_port
    context = $CONTEXT
    context = '/' + context unless context[0].eql? '/'
    return url_string if context.eql? '/' #we need a nontrivial context or nothing to do...
    if ssoi? #if we are under ssoi we assume we are behind apache
      proxy = PrismeConfigConcern.get_proxy_location(host: host, port: port)
      PrismeConfigConcern.create_proxy_css(proxy_string: proxy, context: context)
      return raw url_string.gsub("#{context}", proxy).gsub('/application-', '/' + PrismeConfigConcern::PROXY_CSS_BASE_PREPEND + 'application-')
    else
      return url_string
    end
  end

  def my_controller
    return self if self.is_a? ApplicationController
    return controller
  end

end
