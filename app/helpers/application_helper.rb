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

    def get_concept_metadata(id, view_params)

        coordinates_token = session[:coordinates_token].token
        additional_req_params = {coordToken: coordinates_token}
        additional_req_params.merge!(view_params)

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

    # make sure the passed view params have all components, if it doesn't add the missing components from the default params stored in the session
    def check_view_params(view_params, use_view_params = true)

        # see if we are using the default view params or the edit params
        if use_view_params
            params = session[:default_view_params]
        else
            params = session[:edit_view_params]
        end

        # if the passed params are empty return the entire default object
        if view_params == nil || view_params == ''
            return params
        end

        # check the stated param
        if view_params[:stated] == nil
            view_params[:stated] = params[:stated]
        end

        # check the stamp date param
        if view_params[:time] == nil
            view_params[:time] = params[:time]
        end

        # check the states param
        if view_params[:allowedStates] == nil
            view_params[:allowedStates] = params[:allowedStates]
        end

        return view_params
    end

    def proxy_sensitive(url_string)
        begin
            url_string = url_string.to_s
            host = my_controller.true_address
            port = my_controller.true_port
            context = $CONTEXT
            context = '/' + context unless context[0].eql? '/'
            return url_string if context.eql? '/' #we need a nontrivial context or nothing to do...
            if my_controller.ssoi? #if we are under ssoi we assume we are behind apache
                proxy = PrismeConfigConcern.get_proxy_location(host: host, port: port, context: context)
                PrismeConfigConcern.create_proxy_css(proxy_string: proxy, context: context)
                proxy_sensitive_url_string = url_string.gsub("#{context}", proxy)
                proxy_sensitive_url_string.gsub!('/application-', '/' + PrismeConfigConcern::PROXY_CSS_BASE_PREPEND + 'application-') if (proxy_sensitive_url_string =~ /.*\.css".*/)
                return raw proxy_sensitive_url_string.gsub('//','/') if self.respond_to? :raw
                return proxy_sensitive_url_string.gsub('//','/')
            else
                return url_string
            end
        rescue =>ex
            $log.error("Failed to get proxy data returning original url #{url_string}... #{ex}")
            return url_string
        end
    end

    def my_controller
        return self if self.is_a? ApplicationController
        return controller
    end

end
