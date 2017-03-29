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

require './lib/isaac_rest/taxonomy_rest'
require './lib/rails_common/util/controller_helpers'
require './lib/isaac_rest/search_apis_rest'

include ERB::Util

##
# KometDashboardController -
# handles the loading of the taxonomy tree
class KometDashboardController < ApplicationController
    include TaxonomyConcern, ConceptConcern, InstrumentationConcern, SearchApis
    include CommonController, TaxonomyHelper

    #before_action :setup_routes, :setup_constants, :only => [:dashboard] #todo Ask Tim why is this in app controller too?  OK to whack?
    after_filter :byte_size unless Rails.env.production?
    skip_before_action :ensure_roles, only: [:version]
    skip_after_action :verify_authorized, only: [:version]
    skip_before_action :read_only, only: [:version]
    before_action :can_edit_concept, only: [:get_concept_create_info, :create_concept, :get_concept_edit_info, :edit_concept, :clone_concept, :change_concept_state]

    ##
    # load_tree_data - RESTful route for populating the taxonomy tree using an http :GET
    # The current tree node is identified in the request params with the key :concept_id
    # If the tree is reversed so we are searching for parents of this node is identified in the request params with the key :parent_search (true/false)
    # If the parent of this node was already doing a reverse search is identified in the request params with the key :parent_reversed (true/false)
    # [Object] view_params - various parameters related to the view filters the user wants to apply - see full definition comment at top of komet_dashboard_controller file
    #@return [json] the tree nodes to insert into the tree at the parent node passed in the request
    def load_tree_data

        # roles = session[Roles::SESSION_ROLES_ROOT][Roles::SESSION_USER_ROLES]
        # if(roles.include?(Roles::DEV_SUPER_USER))
        #   #do something
        # end
        # CRIS, test flash code
        # resp = CoordinateRest.get_coordinate(action: CoordinateRestActions::ACTION_COORDINATES_TOKEN, additional_req_params: {foo: 'faa'})
        # resp.rest_exception.flash_error
        # resp.flash_error   (both work)
        # if resp.is_a? CommonRest::UnexpectedResponse
        #   resp.flash_error
        # end
        #
        # resp.flash_error if resp.respond_to? :flash_error

        selected_concept_id = params[:concept_id]
        parent_search = params[:parent_search]
        parent_reversed = params[:parent_reversed]
        tree_walk_levels = params[:tree_walk_levels]
        multi_path = params[:multi_path]
        @view_params = check_view_params(params[:view_params])

        # check to make the number of levels to walk the tree was passed in
        if tree_walk_levels == nil
            tree_walk_levels = 1
        else
            tree_walk_levels = tree_walk_levels.to_i
        end

        # check to make sure the flag for exploring multiple parent paths was passed in
        if multi_path == nil
            multi_path = true
        end

        tree_nodes = populate_tree(selected_concept_id, parent_search, parent_reversed, tree_walk_levels, multi_path)

        render json: tree_nodes
    end

    def populate_tree(selected_concept_id, parent_search, parent_reversed, tree_walk_levels, multi_path)

        coordinates_token = session[:coordinates_token].token
        root = selected_concept_id.eql?('#')

        additional_req_params = {coordToken: coordinates_token, sememeMembership: true}
        additional_req_params.merge!(@view_params)

        if boolean(parent_search)
            tree_walk_levels = 100
            additional_req_params[:childDepth] = 0
            additional_req_params[:parentHeight] = tree_walk_levels
        else

            additional_req_params[:childDepth] = tree_walk_levels
            additional_req_params[:parentHeight] = 1
        end

        if root

            # load the ISAAC root node and children
            isaac_concept = TaxonomyRest.get_isaac_root(additional_req_params: additional_req_params)

            if isaac_concept.is_a? CommonRest::UnexpectedResponse
                return []
            end

            inactive_class = ''

            # if the node is inactive apply the correct class
            if isaac_concept.conVersion.state.enumName && isaac_concept.conVersion.state.enumName.downcase.eql?('inactive')
                inactive_class = ' komet-inactive-tree-node'
            end

            # load the root node into our return variable
            # TODO - remove the hard-coding of type to 'vhat' when the type flags are implemented in the REST APIs
            root_anchor_attributes = { class: 'komet-context-menu' + inactive_class, 'data-menu-type' => 'concept', 'data-menu-uuid' => isaac_concept.conChronology.identifiers.uuids.first,
                                       'data-menu-state' => isaac_concept.conVersion.state.enumName, 'data-menu-concept-text' => isaac_concept.conChronology.description,
                                       'data-menu-concept-terminology-type' => 'vhat'}
            root_node = {id: 0, concept_id: isaac_concept.conChronology.identifiers.uuids.first, text: isaac_concept.conChronology.description, parent_reversed: false, parent_search: parent_search, icon: 'komet-tree-node-icon komet-tree-node-primitive', a_attr: root_anchor_attributes, state: {opened: 'true'}}
        else
            isaac_concept = TaxonomyRest.get_isaac_concept(uuid: selected_concept_id, additional_req_params: additional_req_params)
        end

        if isaac_concept.is_a? CommonRest::UnexpectedResponse
            return []
        end

        raw_nodes = process_rest_concept(isaac_concept, tree_walk_levels, first_level: true, parent_search: parent_search, multi_path: multi_path)
        processed_nodes = process_tree_level(raw_nodes, [], parent_search, parent_reversed)

        if root

            root_node[:children] = processed_nodes
            return [root_node]
        else
            return processed_nodes
        end
    end

    def process_rest_concept(concept, tree_walk_levels, first_level: false, parent_search: false, multi_path: true)

        concept_nodes = []
        has_many_parents = false

        node = {}
        node[:id] = concept.conChronology.identifiers.uuids.first
        node[:text] = concept.conChronology.description
        node[:has_children] = !concept.children.nil? && concept.children.length > 0
        node[:defined] = concept.isConceptDefined
        node[:state] = concept.conVersion.state.enumName
        node[:author] = concept.conVersion.authorSequence
        node[:module] = concept.conVersion.moduleSequence
        node[:path] = concept.conVersion.pathSequence
        node[:refsets] = concept.sememeMembership
        # TODO - remove the hard-coding of type to 'vhat' when the type flags are implemented in the REST APIs
        node[:terminology_type] = 'vhat'

        if node[:text] == nil
            node[:text] = '[No Description]'
        end

        if node[:defined].nil?
            node[:defined] = false
        end

        if node[:has_children]
            node[:child_count] = concept.children.length

        elsif tree_walk_levels == 0 && concept.childCount != 0

            node[:child_count] = concept.childCount
            node[:has_children] = true
            node[:has_children] = true

        else
            node[:child_count] = 0
        end

        node[:has_parents] = !concept.parents.nil?

        if node[:has_parents]
            node[:parent_count] = concept.parents.length

        elsif tree_walk_levels == 0 && concept.parentCount != 0 && boolean(parent_search)

            node[:parent_count] = concept.parentCount
            node[:has_parents] = true

        else
            node[:parent_count] = 0
        end

        if !boolean(parent_search) && node[:child_count] != 0
            node[:badge] = "&nbsp;&nbsp;<span class=\"badge badge-success\" title=\"#{node[:child_count]} children\">#{node[:child_count]}</span>"

        elsif boolean(parent_search) && node[:parent_count] != 0
            node[:badge] = "&nbsp;&nbsp;<span class=\"badge badge-success\" title=\"#{node[:parent_count]} parents\">#{node[:parent_count]}</span>"
        else
            node[:badge] = ''
        end

        node[:parents] = []

        # if this node has parents and we want to see all parent paths then get the details of each parent
        if tree_walk_levels > 0  && !boolean(parent_search) && node[:parent_count] > 1 && boolean(multi_path)

            has_many_parents = true

            if first_level
                node[:badge] = "&nbsp;&nbsp;<span class=\"badge badge-success\" title=\"#{node[:parent_count]} parents\">#{node[:parent_count]}</span>"
            end

            concept.parents.each do |parent|

                parent_node = {}

                parent_node[:id] = parent.conChronology.identifiers.uuids.first
                parent_node[:text] = parent.conChronology.description
                parent_node[:defined] = parent.isConceptDefined
                parent_node[:state] = parent.conVersion.state.enumName
                parent_node[:author] = parent.conVersion.authorSequence
                parent_node[:module] = parent.conVersion.moduleSequence
                parent_node[:path] = parent.conVersion.pathSequence
                parent_node[:has_parents] = parent.parentCount.to_i > 0
                parent_node[:parent_count] = parent.parentCount
                # TODO - remove the hard-coding of type to 'vhat' when the type flags are implemented in the REST APIs
                node[:terminology_type] = 'vhat'

                if node[:parent_count] != 0
                    parent_node[:badge] = "&nbsp;&nbsp;<span class=\"badge badge-success\" title=\"#{parent_node[:parent_count]} parents\">#{parent_node[:parent_count]}</span>"
                end

                if parent_node[:defined].nil?
                    parent_node[:defined] = false
                end

                node[:parents] << parent_node
            end
        end

        relation = :children

        # if we are walking up the tree toward the root node get the parents of the current node, otherwise get the children
        if tree_walk_levels > 0 && boolean(parent_search) && !concept.parents.nil?

            relation = :parents
            related_concepts = concept.parents

        elsif tree_walk_levels > 0 && !boolean(parent_search) && !concept.children.nil?
            related_concepts = concept.children
        else
            related_concepts = []
        end

        processed_related_concepts = []

        related_concepts.each do |related_concept|
            processed_related_concepts.concat(process_rest_concept(related_concept, tree_walk_levels - 1, parent_search: parent_search, multi_path: multi_path))
        end

        if first_level

            if has_many_parents
                concept_nodes << node
            end

            concept_nodes.concat(processed_related_concepts)
        else

            $log.trace('*** data process: ' + node[:text].to_s)
            node[relation] = processed_related_concepts
            concept_nodes << node
        end

        concept_nodes
    end

    def process_tree_level (raw_nodes, tree_nodes, parent_search_param, parent_reversed_param)

        raw_nodes.each do |raw_node|

            anchor_attributes = { class: 'komet-context-menu',
                                  'data-menu-type' => 'concept',
                                  'data-menu-uuid' => raw_node[:id],
                                  'data-menu-state' => raw_node[:state],
                                  'data-menu-concept-text' => raw_node[:text],
                                  'data-menu-concept-terminology-type' => raw_node[:terminology_type],
                                  'aria-label' => raw_node[:text]
            }
            parent_search = parent_search_param
            parent_reversed = parent_reversed_param
            show_expander = true
            relation = :children
            has_relation = :has_children
            flags = get_tree_node_flag('module', [raw_node[:module]])
            flags << get_tree_node_flag('refset', raw_node[:refsets])
            flags << get_tree_node_flag('path', [raw_node[:path]])

            if raw_node[:state] && raw_node[:state].downcase.eql?('inactive')
                anchor_attributes[:class] << ' komet-inactive-tree-node'
            end

            if boolean(parent_search)

                relation = :parents
                has_relation = :has_parents
            end

            if boolean(raw_node[:defined])
                icon_class = 'komet-tree-node-icon komet-tree-node-defined'
            else
                icon_class = 'komet-tree-node-icon komet-tree-node-primitive'
            end

            # should this child node be reversed and is it the first node to be reversed - comes from node data
            if !boolean(parent_reversed) && raw_node[:parent_count] > 1

                anchor_attributes[:class] << ' komet-reverse-tree-node'
                parent_id = get_next_id
                node_text = 'Parents of ' + CGI::escapeHTML(raw_node[:text]) + raw_node[:badge] + flags
                icon_class << '-arrow'

                parent_nodes = populate_tree(raw_node[:id], true, true, 100, true)

                tree_nodes << {id: parent_id, concept_id: raw_node[:id], text: node_text, children: parent_nodes, parent_reversed: true, parent_search: true, icon: icon_class, a_attr: anchor_attributes, li_attr: {class: 'komet-reverse-tree'}}

                # jump to the next node in raw_nodes
                next

            elsif boolean(parent_search)

                icon_class << '-arrow'
                anchor_attributes[:class] << ' komet-reverse-tree-node'
            end

            # if the node has no children (or no parents if doing a parent search) identify it as a leaf, otherwise it is a branch
            show_expander = false unless raw_node[has_relation]

            node_text = CGI::escapeHTML(raw_node[:text]) + raw_node[:badge] + flags

            node = {id: get_next_id, concept_id: raw_node[:id], text: node_text, parent_reversed: parent_reversed, parent_search: parent_search, stamp_state: raw_node[:state], icon: icon_class, a_attr: anchor_attributes}

            if raw_node[relation].length == 0
                node[:children] = show_expander
            else
                node[:state] = {opened: 'true'}
            end

            if raw_node[relation].length > 0
                node[:children] = process_tree_level(raw_node[relation], [], parent_search_param, parent_reversed_param)
            end

            tree_nodes << node

        end

        tree_nodes
    end

    ##
    # get_concept_information - RESTful route for populating concept details pane using an http :GET
    # The current tree node representing the concept is identified in the request params with the key :concept_id
    # [Object] view_params - various parameters related to the view filters the user wants to apply - see full definition comment at top of komet_dashboard_controller file
    # The javascript partial to render is identified in the request params with the key :partial
    # @return [javascript] render a javascript partial that re-renders all needed partials
    def get_concept_information

        @concept_id = params[:concept_id]
        @viewer_id =  params[:viewer_id]
        @viewer_action = params[:viewer_action]
        @view_params = check_view_params(params[:view_params])

        if @viewer_id == nil || @viewer_id == '' || @viewer_id == 'new'
            @viewer_id = get_next_id
        end

        get_concept_attributes(@concept_id, @view_params)

        # get the rest of the concept information unless the attributes were not returned
        unless @concept_text == nil

            get_concept_descriptions(@concept_id, @view_params)
            get_concept_sememes(@concept_id, @view_params)
            get_concept_refsets(@concept_id, @view_params)
        end

        # do any view_param processing needed for the GUI - always call this last before rendering
        @view_params = get_gui_view_params(@view_params)

        render partial: params[:partial]
    end

    ##
    # get_concept_attributes - RESTful route for populating concept attribute tab using an http :GET
    # The current tree node representing the concept is identified in the request params with the key :concept_id
    # @param [Object] view_params - various parameters related to the view filters the user wants to apply - see full definition comment at top of komet_dashboard_controller file
    # @param [Boolean] clone - Are we cloning a concept
    # @return none - setting the @attributes variable
    def get_concept_attributes(concept_id = nil, view_params = nil, clone = false)

        if concept_id == nil && params[:concept_id]
            concept_id = params[:concept_id]
        end

        if view_params == nil && params[:view_params]
            view_params = check_view_params(params[:view_params])
        end

        @attributes =  get_attributes(concept_id, view_params, clone)
    end

    ##
    # get_concept_descriptions - RESTful route for populating concept summary tab using an http :GET
    # The current tree node representing the concept is identified in the request params with the key :concept_id
    # @param [Object] view_params - various parameters related to the view filters the user wants to apply - see full definition comment at top of komet_dashboard_controller file
    # @param [Boolean] clone - Are we cloning a concept
    # @return none - setting the @descriptions variable
    def get_concept_descriptions(concept_id = nil, view_params = nil, clone = false)

        if concept_id == nil && params[:concept_id]
            concept_id = params[:concept_id]
        end

        if view_params == nil && params[:view_params]
            view_params = check_view_params(params[:view_params])
        end

        @descriptions =  get_descriptions(concept_id, view_params, clone)
    end

    ##
    # get_concept_associations - RESTful route for populating concept association tab using an http :GET
    # The current tree node representing the concept is identified in the request params with the key :concept_id
    # @param [Object] view_params - various parameters related to the view filters the user wants to apply - see full definition comment at top of komet_dashboard_controller file
    # @param [Boolean] clone - Are we cloning a concept
    # @return none - setting the @associations variable
    def get_concept_associations(concept_id = nil, view_params = nil, clone = false)

        if concept_id == nil && params[:concept_id]
            concept_id = params[:concept_id]
        end

        if view_params == nil && params[:view_params]
            view_params = check_view_params(params[:view_params])
        end

        @associations =  get_associations(concept_id, view_params, clone)
    end

    ##
    # get_concept_sememes - RESTful route for populating concept sememes section using an http :GET
    # The current tree node representing the concept is identified in the request params with the key :concept_id
    # @param [Object] view_params - various parameters related to the view filters the user wants to apply - see full definition comment at top of komet_dashboard_controller file
    # @param [Boolean] clone - Are we cloning a concept
    # @return none - setting the @concept_sememes variable
    def get_concept_sememes(concept_id = nil, view_params = nil, clone = false)

        if concept_id == nil && params[:concept_id]
            concept_id = params[:concept_id]
        end

        if view_params == nil && params[:view_params]
            view_params = check_view_params(params[:view_params])
        end

        @concept_sememes = get_attached_sememes(concept_id, view_params, clone)
    end

    ##
    # get_concept_refsets - RESTful route for populating concept assemblages section using an http :GET
    # The current tree node representing the concept is identified in the request params with the key :concept_id
    # @param [Object] view_params - various parameters related to the view filters the user wants to apply - see full definition comment at top of komet_dashboard_controller file
    # @return none - setting the refsets variable
    def get_concept_refsets(concept_id = nil, view_params = nil)

        return_json = false

        if concept_id == nil && params[:concept_id]

            concept_id = params[:concept_id]
            return_json = true
        end

        if view_params == nil && params[:view_params]
            view_params = check_view_params(params[:view_params])
        end

        @concept_refsets = get_refsets(concept_id, view_params)
        session[:concept_refsets] = @concept_refsets

        if return_json
            render json: @concept_refsets
        end
    end

    def get_concept_children(concept_id: nil, return_json: true, remove_semantic_tag: false, include_definition: false, include_nested: false, view_params: {})

        if concept_id == nil
            concept_id = params[:uuid]
        end

        children = get_direct_children(concept_id, !return_json, remove_semantic_tag, include_definition, include_nested, view_params)

        if return_json
            render json: children
        else
            return children
        end

    end

    # sets the coordinate token from the user preferences parameters and puts the resulting token in the session
    def set_coordinates_token

        # set the params for the API call from the request
        additional_req_params = {}
        additional_req_params[:language] = params[:language]
        additional_req_params[:time] = params[:time]
        additional_req_params[:dialectPrefs] = params[:dialectPrefs]
        additional_req_params[:descriptionTypePrefs] = params[:descriptionTypePrefs]
        additional_req_params[:allowedStates] = params[:allowedStates]
        additional_req_params.merge!(CommonRest::CacheRequest::PARAMS_NO_CACHE)

        $log.debug("set_coordinates_token additional_req_params #{additional_req_params}")
        $log.debug("set_coordinates_token  params[:module_list] #{ params[:module_flags]}")
        $log.debug("set_coordinates_token params[:path_list] #{params[:path_flags]}")
        $log.debug("set_coordinates_token  params[:refset_flags] #{ params[:refset_flags]}")

        # make the call to set the token and put the retuned token into the session
        session[:coordinates_token] = CoordinateRest.get_coordinate(action: CoordinateRestActions::ACTION_COORDINATES_TOKEN, additional_req_params: additional_req_params)
        $log.info("set_coordinates_token session[:coordinates_token] #{ session[:coordinates_token]}")

        # set the user choices for concept flags into the session for retrieval during concept display
        user_prefs = HashWithIndifferentAccess.new
        user_prefs[:module_flags] = params[:module_flags]
        user_prefs[:path_flags] = params[:path_flags]
        user_prefs[:refset_flags] = params[:refset_flags]
        user_session(UserSession::USER_PREFERENCES, user_prefs)

        # update the default view params in the session
        session[:default_view_params][:time] = params[:time]

        render json: session[:coordinates_token].to_json

    end

    def get_user_preference_info

        # get the coordinates token from the session
        coordinates_token = session[:coordinates_token].token
        additional_req_params = {coordToken: coordinates_token}
        $log.debug("get_user_preference_info token #{coordinates_token}")

        # get the details of what is in the coordinates token
        coordinates_params = CoordinateRest.get_coordinate(action: CoordinateRestActions::ACTION_COORDINATES,additional_req_params: additional_req_params)

        # get the full list of dialects
        unsorted_dialect_options = get_concept_children(concept_id: $isaac_metadata_auxiliary['DIALECT_ASSEMBLAGE']['uuids'].first[:uuid], return_json: false, remove_semantic_tag: true, view_params: session[:edit_view_params])
        $log.debug("get_user_preference_info @unsorted_dialect_options #{unsorted_dialect_options}")

        # get the list of user preferred dialects
        dialect_assemblage_preferences = coordinates_params.languageCoordinate.dialectAssemblagePreferences
        $log.debug("get_user_preference_info dialect_assemblage_preferences #{dialect_assemblage_preferences}")

        preferred_items = []

        # loop through the preferred dialect list and put user preferred dialects into an array first, delete them from the total dialect array
        dialect_assemblage_preferences.each do |preference|

            unsorted_dialect_options.each_with_index do |dialect_option, index|

                if dialect_option[:concept_sequence] == preference

                    preferred_items << dialect_option
                    unsorted_dialect_options.delete_at(index)
                    break
                end
            end
        end

        # add what's left in the total dialect array to the end of the preferred dialects
        @dialect_options = preferred_items + unsorted_dialect_options
        $log.debug("get_user_preference_info @dialect_options #{@dialect_options}")

        # get the full list of description types
        unsorted_description_type_options = get_concept_children(concept_id: $isaac_metadata_auxiliary['DESCRIPTION_TYPE']['uuids'].first[:uuid], return_json: false, remove_semantic_tag: true, view_params: session[:edit_view_params])
        $log.debug("get_user_preference_info @description_type_options #{unsorted_description_type_options}")

        # get the list of user preferred description types
        description_type_preferences = coordinates_params.languageCoordinate.descriptionTypePreferences
        $log.debug("get_user_preference_info description_type_preferences #{description_type_preferences}")

        preferred_items = []

        # loop through the preferred description type list and put user preferred description types into an array first, delete them from the total description type array
        description_type_preferences.each do |preference|

            unsorted_description_type_options.each_with_index do |description_type_option, index|

                if description_type_option[:concept_sequence] == preference

                    preferred_items << description_type_option
                    unsorted_description_type_options.delete_at(index)
                    break
                end
            end
        end

        # add what's left in the total description type array to the end of the preferred description types
        @description_type_options = preferred_items + unsorted_description_type_options
        $log.debug("get_user_preference_info @description_type_options #{@description_type_options}")

        # get the full list of languages
        @language_options = get_concept_children(concept_id: $isaac_metadata_auxiliary['LANGUAGE']['uuids'].first[:uuid], return_json: false, remove_semantic_tag: true, view_params: session[:edit_view_params])
        $log.debug("get_user_preference_info @language_options #{@language_options}")

        # get the user selected language
        @language_coordinate = coordinates_params.languageCoordinate.language
        $log.debug("get_user_preference_info @language_coordinate #{@language_coordinate}")

        # get the user selected STAMP date they wish to view - if it is the max java date use the string 'latest'
        if java.lang.Long::MAX_VALUE == coordinates_params.taxonomyCoordinate.stampCoordinate.time
            @stamp_date = 'latest'
        else
            @stamp_date = coordinates_params.taxonomyCoordinate.stampCoordinate.time
        end

        $log.debug("get_user_preference_info @stamp_date #{@stamp_date}")

        # get the user selected view state preference
        allowed_state_preference = coordinates_params.stampCoordinate.allowedStates
        $log.debug("get_user_preference_info allowed_states #{allowed_state_preference}")

        # set the allowed_states variable based on the user preference
        if allowed_state_preference.length > 1
            @allowed_states = 'both'
        else
            @allowed_states = allowed_state_preference.first.enumName.downcase
        end

        $log.debug("get_user_preference_info @allowed_states #{@allowed_states}")

        user_prefs = user_session(UserSession::USER_PREFERENCES)

        # if the user preferences from the session is not null, get the users flag preferences from it
        unless user_prefs.nil?

            module_flag_preferences = user_prefs[:module_flags]
            path_flag_preferences = user_prefs[:path_flags]
            refset_flag_preferences = user_prefs[:refset_flags]
        end

        $log.debug("get_user_preference_info module_flag_preferences #{module_flag_preferences}")
        $log.debug("get_user_preference_info path_flag_preferences #{path_flag_preferences}")
        $log.debug("get_user_preference_info refset_flag_preferences #{refset_flag_preferences}")

        @path_flags = []

        # if the user doesn't have current preferences
        if path_flag_preferences.nil?

            # get the full list of paths
            path_list = get_concept_children(concept_id: $isaac_metadata_auxiliary['PATH']['uuids'].first[:uuid], return_json: false, remove_semantic_tag: true, view_params: session[:edit_view_params])
            $log.debug("get_user_preference_info path_list #{path_list}")

            # loop thru the full path list to build an array of flag options
            path_list.each do |path|
                @path_flags << {id: path[:concept_sequence], text: path[:text], color: '', shape: 'None', shape_name: 'None'}
            end
        else

            # loop thru their preferences to build an array of flag options
            path_flag_preferences.each do |preference|
                @path_flags << {id: preference[1][:id], text: preference[1][:text], color: preference[1][:color], shape: preference[1][:shape], shape_name: get_shape_name(preference[1][:shape])}
            end
        end

        $log.debug("get_user_preference_info @path_flags #{@path_flags}")

        @module_flags = []

        # if the user doesn't have current preferences
        if module_flag_preferences.nil?

            # get the full list of modules
            module_list = get_concept_children(concept_id: $isaac_metadata_auxiliary['MODULE']['uuids'].first[:uuid], return_json: false, remove_semantic_tag: true, view_params: session[:edit_view_params])
            $log.debug("get_user_preference_info module_list #{module_list}")

            # loop thru the full module list to build an array of flag options
            module_list.each do |komet_module|
                @module_flags << {id: komet_module[:concept_sequence], text: komet_module[:text], color: '', shape: 'None', shape_name: 'None'}
            end
        else

            # loop thru their preferences to build an array of flag options
            module_flag_preferences.each do |preference|
                @module_flags << {id: preference[1][:id], text: preference[1][:text], color: preference[1][:color], shape: preference[1][:shape], shape_name: get_shape_name(preference[1][:shape])}
            end
        end

        $log.debug("get_user_preference_info @module_flags #{@module_flags}")

        additional_req_params[:childDepth] = 50
        additional_req_params.merge!(session[:edit_view_params])

        # get the assemblage concept so we can get all children (refset concepts) from it
        assemblages = TaxonomyRest.get_isaac_concept(uuid: $isaac_metadata_auxiliary['ASSEMBLAGE']['uuids'].first[:uuid], additional_req_params: additional_req_params)

        # if the assemblage concept is loaded
        unless assemblages.is_a? CommonRest::UnexpectedResponse

            # process the children of the assemblage concept into a full list of refsets
            @refset_options = process_refset_list(assemblages)
            $log.debug("get_user_preference_info @refset_options #{@refset_options}")

            @refset_flags = []

            # if the user has current preferences loop thru them to build an array of flag options
            unless refset_flag_preferences.nil?

                refset_flag_preferences.each do |preference|
                    @refset_flags << {id: preference[1][:id], text: preference[1][:text], color: preference[1][:color], shape: preference[1][:shape], shape_name: get_shape_name(preference[1][:shape])}
                end
            end

            $log.debug("get_user_preference_info @refset_flags #{@refset_flags}")
        end
    end

    def get_shape_name(classname)

        if classname == 'None'
            return 'None'
        elsif classname == 'glyphicon glyphicon-stop'
            return 'Square'
        elsif classname == 'glyphicon glyphicon-star'
            return 'Star'
        elsif classname == 'fa fa-circle'
            return 'Circle'
        elsif classname == 'glyphicon glyphicon-triangle-top'
            return 'Triangle'
        elsif classname == 'glyphicon glyphicon-asterisk'
            return 'Asterisk'
        end
    end

    def process_refset_list(concept)

        refset_nodes = {}

        node = {}
        node[concept.conChronology.identifiers.sequence] = concept.conChronology.description
        has_children = concept.children.length > 0

        # get the children
        if has_children
            children = concept.children
        else

            children = []
            refset_nodes.merge!(node)
        end

        children.each do |child|
            refset_nodes.merge!(process_refset_list(child))
        end

        refset_nodes
    end

    def get_concept_description_types

        coordinates_token = session[:coordinates_token].token
        containing_concept_id = 'fc134ddd-9a15-5540-8fcc-987bf2af9198'
        types = []

        description_types = TaxonomyRest.get_isaac_concept(uuid: containing_concept_id, additional_req_params: {coordToken: coordinates_token}.merge!(session[:edit_view_params]))

        if !description_types.is_a? CommonRest::UnexpectedResponse

            description_types.children.each do |description_type|
                types << {concept_id: description_type.conChronology.identifiers.uuids.first, description: description_type.conChronology.description}
            end

            return types
        end
    end

    def get_concept_create_info

        @concept_id = params[:concept_id]
        @viewer_id = params[:viewer_id]
        @parent_id = params[:parent_id]
        @parent_text = params[:parent_text]
        @parent_type = params[:parent_type]
        @view_params = session[:edit_view_params]
        @description_types = get_concept_description_types
        @viewer_action = params[:viewer_action]
        @viewer_previous_content_id = params[:viewer_previous_content_id]
        @viewer_previous_content_type = params[:viewer_previous_content_type]

        if @parent_id == nil

            @parent_id = ''
            @parent_text = ''
            @parent_type = ''
        end

        if @viewer_id == nil || @viewer_id == '' || @viewer_id == 'new'
            @viewer_id = get_next_id
        end

        # do any view_param processing needed for the GUI - always call this last before rendering
        @view_params = get_gui_view_params(@view_params)

        render partial: params[:partial]
    end

    def create_concept

        description_type = params[:komet_create_concept_description_type]
        preferred_term = params[:komet_create_concept_description]
        parent_concept_id = params[:komet_create_concept_parent]
        parent_concept_text = params[:komet_create_concept_parent_display]
        parent_concept_type = params[:komet_create_concept_parent_type]

        begin
            body_params = {
                fsn: preferred_term,
                parentConceptIds: [parent_concept_id],
                descriptionLanguageConceptId: $isaac_metadata_auxiliary['ENGLISH_LANGUAGE']['uuids'].first[:uuid],
                descriptionPreferredInDialectAssemblagesConceptIds: [$isaac_metadata_auxiliary['US_ENGLISH_DIALECT']['uuids'].first[:uuid]]
            }

            # if it is present get the description type concept sequence from the uuid
            if description_type != ''
                body_params[:extendedDescriptionTypeConcept] = description_type
            end

            new_concept_id = ConceptRest::get_concept(action: ConceptRestActions::ACTION_CREATE, additional_req_params: {editToken: get_edit_token}, body_params: body_params )

            if new_concept_id.is_a? CommonRest::UnexpectedResponse
                render json: {concept_id: nil} and return
            end

        rescue => exception
            render json: {concept_id: nil} and return
        end

        # add the parent concept to the concept recents array in the session
        add_to_recents(CONCEPT_RECENTS, parent_concept_id, parent_concept_text, parent_concept_type)

        # clear taxonomy caches after writing data
        clear_rest_caches

        render json: {concept_id: new_concept_id.uuid}
    end

    def get_concept_edit_info

        @concept_id = params[:concept_id]
        @viewer_id =  params[:viewer_id]
        @viewer_action = params[:viewer_action]
        @viewer_previous_content_id = params[:viewer_previous_content_id]
        @viewer_previous_content_type = params[:viewer_previous_content_type]
        @view_params = session[:edit_view_params]
        clone = false

        if @viewer_id == nil || @viewer_id == '' || @viewer_id == 'new'
            @viewer_id = get_next_id
        end

        if @viewer_action == 'clone_concept'
            clone = true
        end

        get_concept_attributes(@concept_id, @view_params, clone)
        get_concept_sememes(@concept_id, @view_params, clone)
        get_concept_descriptions(@concept_id, @view_params, clone)
        get_concept_associations(@concept_id, @view_params, clone)

        @language_options = get_concept_children(concept_id: $isaac_metadata_auxiliary['LANGUAGE']['uuids'].first[:uuid], return_json: false, remove_semantic_tag: true, view_params: @view_params)
        # TODO - Change get_concept_children function to pull all leaf nodes so we can stop hardcoding this uuid
        @dialect_options = get_concept_children(concept_id: $isaac_metadata_auxiliary['DIALECT_ASSEMBLAGE']['uuids'].first[:uuid], return_json: false, remove_semantic_tag: true, view_params: @view_params)
        @case_options = get_concept_children(concept_id: $isaac_metadata_auxiliary['DESCRIPTION_CASE_SIGNIFICANCE']['uuids'].first[:uuid], return_json: false, remove_semantic_tag: true, view_params: @view_params)
        @acceptability_options = get_concept_children(concept_id: $isaac_metadata_auxiliary['DESCRIPTION_ACCEPTABILITY']['uuids'].first[:uuid], return_json: false, remove_semantic_tag: true, view_params: @view_params)
        @description_type_options = get_concept_children(concept_id: $isaac_metadata_auxiliary['DESCRIPTION_TYPE']['uuids'].first[:uuid], return_json: false, remove_semantic_tag: true, view_params: @view_params)
        # TODO - Change get_concept_children function to pull all leaf nodes so we can stop hardcoding this uuid
        @description_extended_type_options = get_concept_children(concept_id: '09c43aa9-eaed-5217-bc5f-23cacca4df38', return_json: false, remove_semantic_tag: true, view_params: @view_params)
        @association_type_options = get_association_types(@view_params)

        if clone
            @concept_id = get_next_id
        end

        # do any view_param processing needed for the GUI - always call this last before rendering
        @view_params = get_gui_view_params(@view_params)

        render partial: params[:partial]
    end

    def get_new_property_info

        sememe_id = params[:sememe]
        sememe_text = params[:sememe_display]
        sememe_type = params[:sememe_type]

        sememe = get_sememe_definition_details(sememe_id, session[:edit_view_params])

        if sememe[:data].empty?
            render json: {} and return
        end

        # add the parent concept to the concept recents array in the session
        add_to_recents(CONCEPT_RECENTS + CONCEPT_RECENTS_SEMEME, sememe_id, sememe_text, sememe_type)

        render json: sememe
    end

    def edit_concept

        concept_id =  params[:concept_id]
        failed_writes = []

        # this is a lambda to be used to process sememes nested under the concept and descriptions
        process_sememes = ->(referenced_id, sememes, type, error_text_prefix = '') {

            sememes.each do |sememe_instance_id, sememe|

                begin

                    # get the sememe definition ID  and name
                    sememe_definition_id = sememe['sememe']
                    sememe_name = sememe['sememe_name']

                    if sememe_name == nil
                        sememe_name = ''
                    end

                    # remove the sememe and sememe name properties
                    sememe.delete('sememe')
                    sememe.delete('sememe_name')

                    if sememe[:state].downcase == 'active'
                        active = true
                    else
                        active = false
                    end

                    # remove the state property
                    sememe.delete('state')

                    body_params = {active: active, columnData: []}
                    additional_req_params = {editToken: get_edit_token}

                    sememe.each do |field_id, field|
                        body_params[:columnData] << {columnNumber: field['column_number'], data: field['value'], '@class' => field['data_type_class']}
                    end

                    # if the sememe ID is a UUID, then it is an existing sememe to be updated, otherwise it is a new sememe to be created
                    if is_id?(sememe_instance_id)
                        return_value = SememeRest::get_sememe(action: SememeRestActions::ACTION_SEMEME_UPDATE, uuid_or_id: sememe_instance_id, additional_req_params: additional_req_params, body_params: body_params)
                    else

                        body_params[:assemblageConcept] = sememe_definition_id
                        body_params[:referencedComponent] = referenced_id

                        return_value = SememeRest::get_sememe(action: SememeRestActions::ACTION_SEMEME_CREATE, additional_req_params: additional_req_params, body_params: body_params)
                    end

                    # if the sememe create or update failed, mark it
                    if return_value.is_a? CommonRest::UnexpectedResponse
                        failed_writes << {id: referenced_id + '_' + sememe_instance_id, text: error_text_prefix + type + ': ' + sememe_name, type: type}
                    end

                rescue => exception

                    $log.error(exception)
                    failed_writes << {id: referenced_id + '_' + sememe_instance_id, text: error_text_prefix + type + ': ' + sememe_name, type: type}
                end
            end
        }

        # if the parent field exists then we are cloning a concept
        if params[:komet_concept_edit_parent]

            create_success = false
            new_concept_id = nil

            begin

                if params[:descriptions]

                    fsn_id = $isaac_metadata_auxiliary['FULLY_SPECIFIED_NAME']['uuids'].first[:uuid]
                    preferred_dialect_id = $isaac_metadata_auxiliary['PREFERRED']['uuids'].first[:uuid]
                    fsn = nil
                    dialects_to_remove = []

                    # loop through the descriptions looking for the FSN
                    params[:descriptions].each do |description_id, description|

                        # When we find the FSN, copy its info and preferred dialects, create the new concept, and break the loop
                        if description['description_type'] == fsn_id

                            body_params = {
                                fsn: description['text'],
                                parentConceptIds: [params[:komet_concept_edit_parent]],
                                descriptionLanguageConceptId: description['description_language']
                            }

                            # process the dialects
                            if description[:dialects]

                                dialects = []

                                description[:dialects].each do |dialect_id, dialect|

                                    if dialect['acceptability'] == preferred_dialect_id

                                        dialect['dialect_id'] = dialect_id
                                        dialects << dialect['dialect']
                                        dialects_to_remove << dialect
                                    end
                                end
                            else
                                dialects << $isaac_metadata_auxiliary['US_ENGLISH_DIALECT']['uuids'].first[:uuid]
                            end

                            # add the preferred dialects from the FSN
                            body_params[:descriptionPreferredInDialectAssemblagesConceptIds] = dialects

                            new_concept_id = ConceptRest::get_concept(action: ConceptRestActions::ACTION_CREATE, additional_req_params: {editToken: get_edit_token}, body_params: body_params )

                            # if the concept create failed, break out of the loop
                            if new_concept_id.is_a? CommonRest::UnexpectedResponse
                                break
                            end

                            fsn = description
                            fsn_id = description_id
                            create_success = true
                            break
                        end
                    end
                end

            rescue => exception

                $log.error(exception)
                create_success = false
            end

            # if the concept create did not happen, return with a failed message, otherwise copy the new concept ID into the concept_id field to continue with the edit
            if create_success
                concept_id = new_concept_id.uuid

                dialects_to_remove.each_with_index do |dialect, index|

                    fsn[:dialects][new_concept_id.dialectSememes[index].uuids.first] = dialect
                    fsn[:dialects].delete(dialect['dialect_id'])
                end

                # Copy the FSN into a new additional_req_params entry using the returned ID from the newly created FSN, then delete the old key
                params[:descriptions][new_concept_id.fsnDescriptionSememe.uuids.first] = fsn
                params[:descriptions].delete(fsn_id)

            else
                render json: {concept_id: concept_id, failed: {id: concept_id, text: 'Clone Concept: The new concept was unable to be created.' , type: 'clone'}} and return
            end
        end

        if params[:concept_state]

            if params[:concept_state].downcase == 'active'
                active = true
            else
                active = false
            end

            return_value = ComponentRest::get_component(action: ComponentRestActions::ACTION_UPDATE_STATE, uuid_or_id: concept_id, additional_req_params: {editToken: get_edit_token, active: active})

            # if the concept state change failed, mark it
            if return_value.is_a? CommonRest::UnexpectedResponse
                failed_writes << {id: concept_id, text: params[:concept_state], type: 'concept'}
            end
        end

        if params[:properties]
            process_sememes.call(concept_id, params[:properties], 'concept property')
        end

        if params[:descriptions]

            params[:descriptions].each do |description_id, description|

                additional_req_params = {editToken: get_edit_token}

                if description['description_state'].downcase == 'active'
                    active = true
                else
                    active = false
                end

                body_params = {
                    caseSignificanceConcept: description['description_case_significance'],
                    languageConcept: description['description_language'],
                    text: description['text'],
                    descriptionTypeConcept: description['description_type'],
                    active: active
                }

                # if the description ID is a UUID, then it is an existing description to be updated, otherwise it is a new description to be created
                if is_id?(description_id)

                    return_value = SememeRest::get_sememe(action: SememeRestActions::ACTION_DESCRIPTION_UPDATE, uuid_or_id: description_id, additional_req_params: additional_req_params, body_params: body_params)

                    # if the description create or update failed, mark it and skip to the next description. Do not process its dialects or properties.
                    if return_value.is_a? CommonRest::UnexpectedResponse

                        failed_writes << {id: description_id, text: description['text'], type: 'description'}
                        next
                    end

                    # process the dialects
                    if description[:dialects]

                        description[:dialects].each do |dialect_id, dialect|

                            if is_id?(dialect_id)

                                if dialect['state'].downcase == 'active'
                                    active = true
                                else
                                    active = false
                                end

                                return_value = ComponentRest::get_component(action: ComponentRestActions::ACTION_UPDATE_STATE, uuid_or_id: dialect_id, additional_req_params: {editToken: get_edit_token, active: active})
                            else

                                body_params = {
                                    assemblageConcept: dialect['dialect'],
                                    referencedComponent: description_id,
                                    columnData: [{columnNumber: 0, data: dialect['acceptability'], '@class' => 'gov.vha.isaac.rest.api1.data.sememe.dataTypes.RestDynamicSememeUUID'}]
                                }

                                return_value = SememeRest::get_sememe(action: SememeRestActions::ACTION_SEMEME_CREATE, additional_req_params: {editToken: get_edit_token}, body_params: body_params)
                            end

                            # if the dialect create or update failed, mark it.
                            if return_value.is_a? CommonRest::UnexpectedResponse
                                failed_writes << {id: description_id + '_' + dialect_id, text: 'Description: ' + description['text'] + ' : dialect', type: 'dialect'}
                            end
                        end
                    end

                else

                    preferred = []
                    acceptable = []

                    # process the dialects
                    if description[:dialects]

                        description[:dialects].each do |dialect_id, dialect|

                            if find_metadata_by_id(dialect['acceptability']).downcase == 'preferred'
                                preferred << dialect['dialect']
                            else
                                acceptable << dialect['dialect']
                            end
                        end
                    else
                        preferred << $isaac_metadata_auxiliary['US_ENGLISH_DIALECT']['uuids'].first[:uuid]
                    end

                    if preferred.length > 0
                        body_params[:preferredInDialectAssemblagesIds] = preferred
                    end

                    if acceptable.length > 0
                        body_params[:acceptableInDialectAssemblagesIds] = acceptable
                    end

                    body_params[:referencedComponentId] = concept_id

                    return_value = SememeRest::get_sememe(action: SememeRestActions::ACTION_DESCRIPTION_CREATE, additional_req_params: additional_req_params, body_params: body_params)

                    # if the description create or update failed, mark it and skip to the next description. Do not process its properties.
                    if return_value.is_a? CommonRest::UnexpectedResponse

                        failed_writes << {id: description_id, text: description['text'], type: 'description'}
                        next
                    end

                    description_id = return_value.uuid
                end

                if description[:properties]
                    process_sememes.call(description_id, description[:properties], 'description property', 'Description: ' + description['text'] + ' : ')
                end

            end
        end

        if params[:associations]

            params[:associations].each do |association_id, association|

                body_params = {targetId: association['target']}

                if association['association_state'].downcase == 'active'
                    body_params[:active] = true
                else
                    body_params[:active] = false
                end

                # if the association ID is a UUID, then it is an existing association to be updated, otherwise it is a new association to be created
                if is_id?(association_id)

                    return_value = AssociationRest::get_association(action: AssociationRestActions::ACTION_ITEM_UPDATE, uuid_or_id: association_id, additional_req_params: {editToken: get_edit_token}, body_params: body_params)

                    if return_value.is_a? CommonRest::UnexpectedResponse
                        failed_writes << {id: association_id, text: association['target_display'], type: 'association'}
                    else
                        add_to_recents(CONCEPT_RECENTS + CONCEPT_RECENTS_ASSOCIATION, association['target'], association['target_display'], association['target_type'])
                    end
                else

                    body_params[:associationType] = association['association_type']
                    body_params[:sourceId] = concept_id

                    return_value = AssociationRest::get_association(action: AssociationRestActions::ACTION_ITEM_CREATE, additional_req_params: {editToken: get_edit_token}, body_params: body_params)

                    if return_value.is_a? CommonRest::UnexpectedResponse
                        failed_writes << {id: association_id, text: association['target_display'], type: 'association'}
                    else
                        add_to_recents(CONCEPT_RECENTS + CONCEPT_RECENTS_ASSOCIATION, association['target'], association['target_display'], association['target_type'])
                    end
                end

                return_value
            end
        end

        if params[:remove]

            params[:remove].each do |remove_concept_id, value|
                ComponentRest::get_component(action: ComponentRestActions::ACTION_UPDATE_STATE, uuid_or_id: remove_concept_id, additional_req_params: {editToken: get_edit_token, active: false})

                # if the concept state change failed, mark it
                if return_value.is_a? CommonRest::UnexpectedResponse
                    failed_writes << {id: remove_concept_id, text: 'inactivate', type: 'inactivate'}
                end
            end
        end

        # clear taxonomy caches after writing data
        clear_rest_caches

        render json: {concept_id: concept_id, failed: failed_writes}

    end

    def change_concept_state

        concept_id = params[:concept_id]
        newState = params[:newState]

        results = ComponentRest::get_component(action: ComponentRestActions::ACTION_UPDATE_STATE, uuid_or_id: concept_id, additional_req_params: {editToken: get_edit_token, active: newState})

        if results.is_a? CommonRest::UnexpectedResponse
            render json: {state: nil} and return
        end

        # clear taxonomy caches after writing data
        clear_rest_caches

        render json: {state: newState}
    end

    ##
    # get_concept_suggestions - RESTful route for populating a suggested list of assemblages as a user types into a field via http :GET
    # @param [Object] params[:view_params] - various parameters related to the view filters the user wants to apply - see full definition comment at top of komet_dashboard_controller file
    # @param [String] params[:term] - The term entered by the user to prefix the concept search with
    # @return [json] a list of matching concept text and ids - array of hashes {label:, value:}
    def get_concept_suggestions

        coordinates_token = session[:coordinates_token].token
        view_params = check_view_params(params[:view_params], false)
        search_term = params[:term]
        concept_suggestions_data = []
        additional_req_params = {coordToken: coordinates_token, query: search_term, maxPageSize: 25, expand: 'referencedConcept', mergeOnConcept: true}
        additional_req_params.merge!(view_params)
        restrict_search = params[:restrict_search]

        if search_term.length >= 3 && restrict_search != nil && restrict_search != ''
            additional_req_params[:restrictTo] = restrict_search;
        end

        results = SearchApis.get_search_api(action: ACTION_PREFIX, additional_req_params: additional_req_params)

        results.results.each do |result|

            # TODO - remove the hard-coding of type to 'vhat' when the type flags are implemented in the REST APIs
            concept_suggestions_data << {label: result.referencedConcept.description, value: result.referencedConcept.identifiers.uuids.first, type: 'vhat', matching_text: result.matchText}
        end

        render json: concept_suggestions_data
    end

    ##
    # get_concept_recents - RESTful route for populating a list of recent concept searches via http :GET
    # @return [json] an array of hashes {id:, text:}
    def get_concept_recents

        recents_array = []
        recents_name = params[:recents_name]

        if recents_name == nil
            recents_name = '';
        end

        if session[CONCEPT_RECENTS + recents_name]
            recents_array = session[CONCEPT_RECENTS + recents_name]
        end

        render json: recents_array
    end

    def dashboard
        # user_session(UserSession::WORKFLOW_UUID, '6457fb1f-b67b-4679-8f56-fa811e1e2a6b')

        unless session[:coordinates_token]
            session[:coordinates_token] = CoordinateRest.get_coordinate(action: CoordinateRestActions::ACTION_COORDINATES_TOKEN)
        end

        # if the view params are already in the session put them into a variable for the GUI, otherwise set the default values
        if session[:default_view_params]
            @view_params = session[:default_view_params]
        else

            @view_params = {stated: true, allowedStates: 'active,inactive', time: 'latest', modules: '', path: $isaac_metadata_auxiliary['DEVELOPMENT_PATH']['uuids'].first[:uuid]}

            # set variables for default view parameters that can be accessed from any controller or module
            session[:default_view_params] = @view_params.clone
            # set a variable for view params to be used when pulling data for edits, which should always be the least restricted possible
            session[:edit_view_params] = @view_params.clone

            # create the options for stated/inferred preference controls
            session[:komet_stated_options] = [['Stated', 'true'],['Inferred', 'false']]

            # create the options for stated/inferred preference controls
            session[:komet_allowed_states_options] = [['All', 'active,inactive'],['Active', 'active']]

            session[:komet_module_options] = []

            # get the full list of modules
            module_list = get_concept_children(concept_id: $isaac_metadata_auxiliary['MODULE']['uuids'].first[:uuid], return_json: false, remove_semantic_tag: true, include_nested: true, view_params: session[:edit_view_params])

            # loop thru the full module list to build an array of options in the session, including the nested level of each module
            module_list.each do |komet_module|

                indent = ('-' * komet_module[:level]) + ' '
                session[:komet_module_options] << [indent + komet_module[:text], komet_module[:concept_id], {title: komet_module[:text], 'data-level': komet_module[:level]}]
            end

            session[:komet_path_options] = []

            # get the full list of paths
            path_list = get_concept_children(concept_id: $isaac_metadata_auxiliary['PATH']['uuids'].first[:uuid], return_json: false, remove_semantic_tag: true, view_params: session[:edit_view_params])

            # loop thru the full path list to build an array of options in the session
            path_list.each do |path|
                session[:komet_path_options] << [path[:text], path[:concept_id]]
            end
        end

        get_user_preference_info
        $log.debug("token initial #{session[:coordinates_token].token}" )

        # do any view_param processing needed for the GUI - always call this last before rendering
        @view_params = get_gui_view_params(@view_params)
    end

    # this action is called via javascript if/when the user's session has timed out
    def session_timeout
        clear_user_session
        logout_url_string = ssoi? ? PrismeConfigConcern.logout_link : root_url
        redirect_to logout_url_string
    end

    def metadata
    end

    #http://localhost:3001/komet_dashboard/version?include_isaac=true
    def version
        @version = $PROPS['PRISME.war_version']
        @version = 'Unversioned by PRISME.' if @version.nil?
        @version = {version: @version}
        uuid = $PROPS['PRISME.war_uuid']
        @version[:war_uuid] = uuid.nil? ? 'DEV_BOX' : uuid
        if (params[:include_isaac])
            begin
                system_info_isaac = SystemApis::get_system_api(action: SystemApiActions::ACTION_SYSTEM_INFO)
                @version[:isaac_version] = system_info_isaac.to_jaxb_json_hash
            rescue => ex
                $log.warn("I failed to obtain the isaac version information and it was expressly asked for.  The data will not be sent to prisme. #{ex}")
                $log.warn(ex.backtrace.join("\n"))
            end
        end
        render json: @version
    end

end
