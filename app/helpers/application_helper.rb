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
require './lib/rails_common/util/controller_helpers'

module ApplicationHelper
    include UserSession
    include BootstrapNotifier
    include CommonController
    CONCEPT_RECENTS = 'general_concept_recents'
    CONCEPT_RECENTS_ASSOCIATION = 'association'
    CONCEPT_RECENTS_MAPSET = 'mapset'
    CONCEPT_RECENTS_SEMEME = 'sememe'
    CONCEPT_RECENTS_METADATA = 'metadata'

    def get_user_token
        user_session(UserSession::TOKEN)
    end

    def get_concept_metadata(id, view_params)

        coordinates_token = session[:coordinates_token].token
        additional_req_params = {coordToken: coordinates_token}
        additional_req_params.merge!(get_view_params_for_metadata(view_params))

        version = ConceptRest.get_concept(action: ConceptRestActions::ACTION_DESCRIPTIONS, uuid: id, additional_req_params: additional_req_params)

        if version.is_a? CommonRest::UnexpectedResponse
            return ''
        else
            return version.first.text
        end
    end

    def get_uuids_from_identified_objects(identified_objects)

        uuids = ''

        identified_objects.each_with_index { |identified_object, index|

            if index > 0
                uuids += ','
            end

            uuids += identified_object.uuids.first
        }

        return uuids
    end

    def get_terminology_description_list_from_identified_objects(identified_objects)

        descriptions = ''

        identified_objects.each_with_index { |identified_object, index|

            if index > 0
                descriptions += ','
            end

            descriptions += find_metadata_by_id(identified_object.uuids.first)
        }

        return descriptions
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
            params = session[:default_view_params].clone
        else
            params = session[:edit_view_params].clone
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

        # check the modules param
        if view_params[:modules] == nil
            view_params[:modules] = params[:modules]

        elsif view_params[:modules].kind_of?(Array)

            # make sure that the Issac Module is included or things will break
            unless view_params[:modules].include?($isaac_metadata_auxiliary['ISAAC_MODULE']['uuids'].first[:uuid])
                view_params[:modules] << $isaac_metadata_auxiliary['ISAAC_MODULE']['uuids'].first[:uuid]
            end

            # make sure that the VHA Module is included or things may break
            unless view_params[:modules].include?($isaac_metadata_auxiliary['VHAT_MODULES']['uuids'].first[:uuid])
                view_params[:modules] << $isaac_metadata_auxiliary['VHAT_MODULES']['uuids'].first[:uuid]
            end

            view_params[:modules] = view_params['modules'] * ','
        end

        # check the path param
        if view_params[:path] == nil
            view_params[:path] = params[:path]
        end

        return view_params
    end

    # handle any processing needed so the view_params can be used in the GUI
    def get_gui_view_params (view_params)

        if (view_params[:modules])
            view_params[:modules] = view_params[:modules].split(',')
        end

        return view_params
    end

    # remove keys that would stop metadata calls from working properly from view params
    def get_view_params_for_metadata(view_params)

        # clone the passed in params so we don't overwrite their value and then delete the unnecessary keys
        metadata_view_params = view_params.clone
        metadata_view_params.delete(:modules)
        return metadata_view_params
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

    # get_next_id - generates a unique ID by using the systems nano-second time and date
    # @return [String] returns a unique ID by using the systems nano-second time and date
    def get_next_id
        id = java.lang.System.nanoTime.to_s
        $log.info("*** get_next_id: " + id)
        return id
    end

    ##
    # is_id? - tests to see if the provided ID is really an ID of the type specified
    # @param [String] id - the ID to test
    # @param [String] type - the type of id to test the passed value against. Options are 'uuid' (default), 'nid', 'sequence'
    # @return [String] returns a unique ID by using the systems nano-second time and date
    def is_id?(id, type: 'uuid')

        is_id = false

        # TODO - add support for other id types
        if type == 'uuid'
            is_id = id.to_s.match(/[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}/) != nil
        end

        return is_id
    end

    ##
    # add_to_recents - uses the standard fields for recently searched concepts to add an id and description to an array of these values in the session
    # @param [Symbol] recent_name - The name of the array in the session as a symbol
    # @param [String] id - The id of the searched concept
    # @param [String] description - The description of the searched concept
    # @param [String] type - The terminology type of the searched concept
    # @param [Integer] max_items - The total number of items to store in the array. When array has reached the limit the oldest entry will be removed to make room. Optional, defaults to 20
    # @return [Boolean] returns true if the values were added, false if they were not because they already existed in the array.
    def add_to_recents(recent_name, id, description, type, max_items: 20)

        recents_array = []
        added = false

        # see if the recents array already exists in the session
        if session[recent_name]
            recents_array = session[recent_name]
        end

        # only proceed if the array does not already contain the id and term that were searched for
        already_exist = recents_array.find { |recent|
            (recent[:id] == id && recent[:text] == description)
        }

        if already_exist == nil

            # if the recents array has the max items remove the last item before adding a new one
            if recents_array.length == max_items
                recents_array.delete_at(max_items - 1)
            end

            # put the current items into the beginning of the array
            recents_array.insert(0, {id: id, text: description, type: type})

            # put the array into the session
            session[recent_name] = recents_array
            added = true
        end

        return added
    end

end
