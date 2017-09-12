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
    before_action :can_edit_concept, only: [:get_concept_create_info, :create_concept, :edit_concept, :clone_concept, :change_concept_state, :import]
    before_action :can_get_vuids, only: [:get_generated_vhat_ids]

    ##
    # load_tree_data - RESTful route for populating the taxonomy tree using an http :GET
    # The current tree node is identified in the request params with the key :concept_id
    # If the tree is reversed so we are searching for parents of this node is identified in the request params with the key :parent_search (true/false)
    # If the parent of this node was already doing a reverse search is identified in the request params with the key :parent_reversed (true/false)
    # [Object] view_params - various parameters related to the view filters the user wants to apply - see full definition comment at top of komet_dashboard_controller file
    # @return [json] the tree nodes to insert into the tree at the parent node passed in the request
    def load_tree_data

        # TODO - see if some of these can just be referenced everywhere as params[*] instead of passing variables to all sub functions
        selected_concept_id = params[:concept_id]
        parent_search = params[:parent_search]
        parent_reversed = params[:parent_reversed]
        tree_walk_levels = params[:tree_walk_levels]
        multi_path = params[:multi_path]
        next_page = params[:next_page]
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

        $log.debug("!***! START LOAD TREE DATA PROCESSING")
        tree_nodes = populate_tree(selected_concept_id, parent_search, parent_reversed, tree_walk_levels, multi_path, next_page)
        $log.debug("!***! END LOAD TREE DATA PROCESSING")

        render json: tree_nodes
    end

    def populate_tree(selected_concept_id, parent_search, parent_reversed, tree_walk_levels, multi_path, next_page = nil)

        coordinates_token = session[:coordinates_token].token
        root = selected_concept_id.eql?('#')

        additional_req_params = {coordToken: coordinates_token, sememeMembership: true, maxPageSize: session[:komet_taxonomy_page_size]}
        additional_req_params.merge!(@view_params)

        # check to see if we are getting the next page of child results, if so add the pageNum parameter
        if next_page != nil
            additional_req_params[:pageNum] = next_page
        end

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

            terminology_types = get_uuids_from_identified_objects(isaac_concept.terminologyTypes)

            # load the root node into our return variable
            # TODO - remove the hard-coding of type to 'vhat' when the type flags are implemented in the REST APIs
            root_anchor_attributes = { class: 'komet-context-menu' + inactive_class, 'data-menu-type' => 'concept', 'data-menu-uuid' => isaac_concept.conChronology.identifiers.uuids.first,
                                       'data-menu-state' => isaac_concept.conVersion.state.enumName, 'data-menu-concept-text' => isaac_concept.conChronology.description,
                                       'data-menu-concept-terminology-types' => terminology_types, 'data-menu-js-object' => params[:viewer_id]}
            root_node = {id: 0, concept_id: isaac_concept.conChronology.identifiers.uuids.first, text: isaac_concept.conChronology.description, parent_reversed: false, parent_search: parent_search, icon: 'komet-tree-node-icon komet-tree-node-primitive', a_attr: root_anchor_attributes, state: {opened: 'true'}}
        else
            isaac_concept = TaxonomyRest.get_isaac_concept(uuid: selected_concept_id, additional_req_params: additional_req_params)
        end

        if isaac_concept.is_a? CommonRest::UnexpectedResponse
            return []
        end

        $log.debug("!***! START REST CONCEPT PROCESSING")
        raw_nodes = process_rest_concept(isaac_concept, tree_walk_levels, first_level: true, parent_search: parent_search, multi_path: multi_path)
        $log.debug("!***! END REST CONCEPT PROCESSING")

        $log.debug("!***! START TREE LEVEL PROCESSING")
        processed_nodes = process_tree_level(raw_nodes, [], parent_search, parent_reversed)
        $log.debug("!***! END TREE LEVEL PROCESSING")

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
        node[:has_children] = !concept.children.nil?
        node[:has_unfetched_children] = false
        node[:defined] = concept.isConceptDefined
        node[:state] = concept.conVersion.state.enumName
        node[:author] = concept.conVersion.authorUUID
        node[:module] = concept.conVersion.moduleUUID
        node[:path] = concept.conVersion.pathUUID
        node[:refsets] = concept.sememeMembership

        # TODO - remove the hard-coding of type to 'vhat' when the type flags are implemented in the REST APIs
        node[:terminology_types] = get_uuids_from_identified_objects(concept.terminologyTypes)

        if node[:text] == nil
            node[:text] = '[No Description]'
        end

        if node[:defined].nil?
            node[:defined] = false
        end

        if node[:has_children]
            node[:child_count] = concept.children.paginationData.approximateTotal

        elsif tree_walk_levels == 0 && concept.childCount != 0

            node[:child_count] = concept.childCount
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
                parent_node[:author] = parent.conVersion.authorUUID
                parent_node[:module] = parent.conVersion.moduleUUID
                parent_node[:path] = parent.conVersion.pathUUID
                parent_node[:has_parents] = parent.parentCount.to_i > 0
                parent_node[:parent_count] = parent.parentCount
                # TODO - remove the hard-coding of type to 'vhat' when the type flags are implemented in the REST APIs
                parent_node[:terminology_types] = get_uuids_from_identified_objects(parent.terminologyTypes)

                if node[:parent_count] != 0
                    parent_node[:badge] = "&nbsp;&nbsp;<span class=\"badge badge-success\" aria-label=\"#{parent_node[:parent_count]} parents\">#{parent_node[:parent_count]}</span>"
                end

                if parent_node[:defined].nil?
                    parent_node[:defined] = false
                end

                node[:parents] << parent_node
            end
        end

        relation = :children

        # if we are walking up the tree toward the root node get the parents of the current node, otherwise get the children
        if tree_walk_levels > 0 && boolean(parent_search) && node[:has_parents]

            relation = :parents
            related_concepts = concept.parents

        elsif tree_walk_levels > 0 && !boolean(parent_search) && node[:has_children]
            related_concepts = concept.children.results
        else
            related_concepts = []
        end

        processed_related_concepts = []

        related_concepts.each do |related_concept|
            processed_related_concepts.concat(process_rest_concept(related_concept, tree_walk_levels - 1, parent_search: parent_search, multi_path: multi_path))
        end

        # if the concept has children and the length of the child array is less then then total number of children, then there are paged results
        if !concept.children.nil? && concept.children.results.length < concept.children.paginationData.approximateTotal

            # get the page number for the next page of child results
            nextPageNumber = /pageNum=(\d+)&/.match(concept.children.paginationData.nextUrl).captures[0]

            # make sure we aren't on the last page of results
            if nextPageNumber.to_i <= (concept.children.paginationData.approximateTotal / session[:komet_taxonomy_page_size].to_f).ceil

                # add a node to the end of the child concepts to alert the user that there are more children that haven't been loaded
                processed_related_concepts << {id: node[:id], text: 'This concept has children that have not been fetched. Click here to load them.', next_page: nextPageNumber}
            end
        end

        if first_level

            if has_many_parents
                concept_nodes << node
            end

            concept_nodes.concat(processed_related_concepts)
        else

            node[relation] = processed_related_concepts
            concept_nodes << node
        end

        concept_nodes
    end

    def process_tree_level (raw_nodes, tree_nodes, parent_search_param, parent_reversed_param)

        raw_nodes.each do |raw_node|

            if raw_node[:next_page]

                tree_nodes << {id: get_next_id,
                               concept_id: raw_node[:id],
                               text: raw_node[:text],
                               next_page: raw_node[:next_page],
                               children: false,
                               parent_reversed: false,
                               parent_search: false,
                               icon: 'komet-tree-node-icon fa fa-info-circle',
                               a_attr: {class: 'komet-tree-warning', 'aria-label' => raw_node[:text]}
                }
                next
            end

            anchor_attributes = { class: 'komet-context-menu',
                                  'data-menu-type' => 'concept',
                                  'data-menu-uuid' => raw_node[:id],
                                  'data-menu-state' => raw_node[:state],
                                  'data-menu-concept-text' => raw_node[:text],
                                  'data-menu-concept-terminology-types' => raw_node[:terminology_types],
                                  'data-menu-js-object' => params[:viewer_id],
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

        @descriptions =  get_descriptions(concept_id, @concept_terminology_types, view_params, clone)
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

    def get_concept_children(concept_id: nil, return_json: true, remove_semantic_tag: false, include_definition: false, include_nested: false, view_params: {}, qualifier: '')

        if concept_id == nil
            concept_id = params[:uuid]
        end

        children = get_direct_children(concept_id: concept_id, format_results: !return_json, remove_semantic_tag: remove_semantic_tag, include_definition: include_definition, include_nested: include_nested, view_params: view_params, qualifier: qualifier)

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
        additional_req_params[:language] = params[:'komet_preferences_language']
        additional_req_params[:time] = params[:time]
        additional_req_params[:dialectPrefs] = params[:dialect].keys * ','
        additional_req_params[:descriptionTypePrefs] = params[:description_type].keys * ','
        additional_req_params[:allowedStates] = params[:allowed_states]
        additional_req_params.merge!(CommonRest::CacheRequest::PARAMS_NO_CACHE)

        if additional_req_params[:time].nil? || additional_req_params[:time] == ''
            additional_req_params[:time] = 'latest'
        end

        # make the call to set the token and put the retuned token into the session
        session[:coordinates_token] = CoordinateRest.get_coordinate(action: CoordinateRestActions::ACTION_COORDINATES_TOKEN, additional_req_params: additional_req_params)

        # set the user choices for concept flags into the session for retrieval during concept display
        user_prefs = HashWithIndifferentAccess.new
        user_prefs[:module_flags] = params[:module_flags]
        user_prefs[:path_flags] = params[:path_flags]
        user_prefs[:refset_flags] = params[:refset_flags]
        user_prefs[:generate_vuid] = params[:generate_vuid]
        user_session(UserSession::USER_PREFERENCES, user_prefs)

        # set the taxonomy page size into the session
        session[:komet_taxonomy_page_size] = params[:komet_preferences_taxonomy_page_size]

        # update the default view params in the session
        session[:default_view_params][:time] = additional_req_params[:time]
        session[:default_view_params][:allowedStates] = params[:allowed_states]

        # set the flag that we've changed the params
        session[:view_params_changed] = true

        render json: session[:coordinates_token].to_json

    end

    def get_user_preference_info

        # get the coordinates token from the session
        coordinates_token = session[:coordinates_token].token
        additional_req_params = {coordToken: coordinates_token}

        # get the details of what is in the coordinates token
        coordinates_params = CoordinateRest.get_coordinate(action: CoordinateRestActions::ACTION_COORDINATES,additional_req_params: additional_req_params)

        # get the full list of dialects
        unsorted_dialect_options = get_concept_children(concept_id: $isaac_metadata_auxiliary['DIALECT_ASSEMBLAGE']['uuids'].first[:uuid], return_json: false, remove_semantic_tag: true, view_params: session[:edit_view_params])

        # get the list of user preferred dialects
        dialect_assemblage_preferences = coordinates_params.languageCoordinate.dialectAssemblagePreferences

        preferred_items = []

        # loop through the preferred dialect list and put user preferred dialects into an array first, delete them from the total dialect array
        dialect_assemblage_preferences.each do |preference|

            unsorted_dialect_options.each_with_index do |dialect_option, index|

                if dialect_option[:concept_id] == preference.uuids.first

                    preferred_items << dialect_option
                    unsorted_dialect_options.delete_at(index)
                    break
                end
            end
        end

        # add what's left in the total dialect array to the end of the preferred dialects
        @dialect_options = preferred_items + unsorted_dialect_options

        # get the full list of description types
        unsorted_description_type_options = get_concept_children(concept_id: $isaac_metadata_auxiliary['DESCRIPTION_TYPE']['uuids'].first[:uuid], return_json: false, remove_semantic_tag: true, view_params: session[:edit_view_params])

        # get the list of user preferred description types
        description_type_preferences = coordinates_params.languageCoordinate.descriptionTypePreferences

        preferred_items = []

        # loop through the preferred description type list and put user preferred description types into an array first, delete them from the total description type array
        description_type_preferences.each do |preference|

            unsorted_description_type_options.each_with_index do |description_type_option, index|

                if description_type_option[:concept_id] == preference.uuids.first

                    preferred_items << description_type_option
                    unsorted_description_type_options.delete_at(index)
                    break
                end
            end
        end

        # add what's left in the total description type array to the end of the preferred description types
        @description_type_options = preferred_items + unsorted_description_type_options

        # get the full list of languages and store it in the session if it isn't already there
        if session[:komet_language_options] == nil

            session[:komet_language_options] = []
            language_list = get_concept_children(concept_id: $isaac_metadata_auxiliary['LANGUAGE']['uuids'].first[:uuid], return_json: false, remove_semantic_tag: true, view_params: session[:edit_view_params])

            # loop thru the full languages list to build an array of options
            language_list.each do |language|
                session[:komet_language_options] << [language[:text], language[:concept_id]]
            end
        end

        # get the user selected language
        @language_coordinate = coordinates_params.languageCoordinate.language.uuids.first

        # get the user selected STAMP date they wish to view - if it is the max java date use the string 'latest'
        if java.lang.Long::MAX_VALUE == coordinates_params.taxonomyCoordinate.stampCoordinate.time
            @stamp_date = 'latest'
        else
            @stamp_date = coordinates_params.taxonomyCoordinate.stampCoordinate.time
        end

        # get the user selected view state preference
        allowed_state_preference = coordinates_params.stampCoordinate.allowedStates

        # set the allowed_states variable based on the user preference
        if allowed_state_preference.length > 1
            @allowed_states = 'both'
        else
            @allowed_states = allowed_state_preference.first.enumName.downcase
        end

        user_prefs = user_session(UserSession::USER_PREFERENCES)

        # generate_vuid preference
        if user_prefs[:generate_vuid] == 'true'
            @generate_vuid = 'true'
        else
            @generate_vuid = 'false'
        end

        # if the user preferences from the session is not null, get the users flag preferences from it
        unless user_prefs.nil?

            module_flag_preferences = user_prefs[:module_flags]
            path_flag_preferences = user_prefs[:path_flags]
            refset_flag_preferences = user_prefs[:refset_flags]
        end

        @path_flags = {}

        # if the user doesn't have current preferences
        if path_flag_preferences.nil?

            # get the full list of paths
            path_list = get_concept_children(concept_id: $isaac_metadata_auxiliary['PATH']['uuids'].first[:uuid], return_json: false, remove_semantic_tag: true, view_params: session[:edit_view_params])
            $log.debug("get_user_preference_info path_list #{path_list}")

            # loop thru the full path list to build an array of flag options
            path_list.each do |path|
                @path_flags[path[:concept_sequence]] = {id: path[:concept_sequence], text: path[:text], color: '', shape_class: 'None', shape_name: 'None'}
            end
        else
            @path_flags = path_flag_preferences
        end

        @module_flags = {}

        # if the user doesn't have current preferences
        if module_flag_preferences.nil?

            # get the full list of modules
            module_list = get_concept_children(concept_id: $isaac_metadata_auxiliary['MODULE']['uuids'].first[:uuid], return_json: false, remove_semantic_tag: true, include_nested: true, view_params: session[:edit_view_params])

            # loop thru the full module list to build an array of flag options
            module_list.each do |komet_module|
                @module_flags[komet_module[:concept_sequence]] = {id: komet_module[:concept_sequence], text: komet_module[:text], color: '', shape_class: 'None', shape_name: 'None'}
            end
        else
            @module_flags = module_flag_preferences
        end

        additional_req_params[:childDepth] = 50
        additional_req_params.merge!(session[:edit_view_params])

        @refset_flags = {}

        # if the user has current refset preferences add them as flag options
        unless refset_flag_preferences.nil?
            @refset_flags = refset_flag_preferences
        end

        # render the partial that was passing in to this function
        render partial: params[:partial]
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

            description_types.children.results.each do |description_type|
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
        @parent_terminology_types = params[:parent_terminology_types]
        @view_params = session[:edit_view_params].clone
        @description_types = get_concept_description_types
        @viewer_action = params[:viewer_action]
        @viewer_previous_content_id = params[:viewer_previous_content_id]
        @viewer_previous_content_terminology_types = params[:viewer_previous_content_terminology_types]

        if @parent_id == nil

            @parent_id = ''
            @parent_text = ''
            @parent_terminology_types = ''
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
        parent_concept_terminology_types = params[:komet_create_concept_parent_terminology_types]

        begin
            body_params = {
                fsn: preferred_term.strip,
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
        add_to_recents(CONCEPT_RECENTS, parent_concept_id, parent_concept_text, parent_concept_terminology_types)

        # clear taxonomy caches after writing data
        clear_rest_caches

        render json: {concept_id: new_concept_id.uuid}
    end

    def get_concept_edit_info

        @concept_id = params[:concept_id]
        @viewer_id =  params[:viewer_id]
        @new_concept =  params[:new_concept]
        @viewer_action = params[:viewer_action]
        @viewer_previous_content_id = params[:viewer_previous_content_id]
        @viewer_previous_content_terminology_types = params[:viewer_previous_content_terminology_types]
        @view_params = check_view_params(params[:view_params])
        clone = false

        if @viewer_id == nil || @viewer_id == '' || @viewer_id == 'new'
            @viewer_id = get_next_id
        end

        if @viewer_action == 'clone_concept'
            clone = true
        end

        if @new_concept == nil || @new_concept == ''
            @new_concept = false
        end

        get_concept_attributes(@concept_id, @view_params, clone)
        get_concept_sememes(@concept_id, @view_params, clone)
        get_concept_descriptions(@concept_id, @view_params, clone)
        get_concept_associations(@concept_id, @view_params, clone)

        generate_vuid = user_session(UserSession::USER_PREFERENCES)[:generate_vuid] == 'true'

        # if this is a new VHAT concept and not also a metadata concept add the VHAT ID properties
        if @new_concept && @concept_terminology_types.include?($isaac_metadata_auxiliary['VHAT_MODULES']['uuids'].first[:uuid]) && !@concept_terminology_types.include?($isaac_metadata_auxiliary['ISAAC_MODULE']['uuids'].first[:uuid])

            # add ID properties to the attached sememes
            new_sememe_properties = generate_vhat_properties(generate_vuid)
            @concept_sememes[:field_info].merge!(new_sememe_properties[:field_info])
            @concept_sememes[:rows].concat(new_sememe_properties[:data])

            # add ID properties to the description
            new_sememe_properties = generate_vhat_properties(generate_vuid)
            @descriptions[:descriptions].first[:nested_properties] = new_sememe_properties
            @descriptions[:errors].concat(new_sememe_properties[:errors])
        end

        @language_options = get_concept_children(concept_id: $isaac_metadata_auxiliary['LANGUAGE']['uuids'].first[:uuid], return_json: false, remove_semantic_tag: true, view_params: @view_params)
        @dialect_options = get_concept_children(concept_id: $isaac_metadata_auxiliary['DIALECT_ASSEMBLAGE']['uuids'].first[:uuid], return_json: false, remove_semantic_tag: true, view_params: @view_params)
        @case_options = get_concept_children(concept_id: $isaac_metadata_auxiliary['DESCRIPTION_CASE_SIGNIFICANCE']['uuids'].first[:uuid], return_json: false, remove_semantic_tag: true, view_params: @view_params)
        @acceptability_options = get_concept_children(concept_id: $isaac_metadata_auxiliary['DESCRIPTION_ACCEPTABILITY']['uuids'].first[:uuid], return_json: false, remove_semantic_tag: true, view_params: @view_params)
        @description_type_options = get_concept_children(concept_id: $isaac_metadata_auxiliary['DESCRIPTION_TYPE']['uuids'].first[:uuid], return_json: false, remove_semantic_tag: true, view_params: @view_params)
        @association_type_options = get_association_types(@view_params)

        # if we are cloning a concept replace the concept ID with a placeholder
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
        sememe_terminology_types = params[:sememe_terminology_types]
        concept_terminology_types = params[:concept_terminology_types]
        generated_vuid = false

        # if this is a VHAT concept and not also a metadata concept add the VHAT ID properties
        if concept_terminology_types.include?($isaac_metadata_auxiliary['VHAT_MODULES']['uuids'].first[:uuid]) && !concept_terminology_types.include?($isaac_metadata_auxiliary['ISAAC_MODULE']['uuids'].first[:uuid])
            generated_vuid = nil
        end

        sememe = get_sememe_definition_details(sememe_id, session[:edit_view_params], generated_vuid, concept_terminology_types)

        # if data was returned add the parent concept to the concept recents array in the session
        if !sememe[:data].empty?
            add_to_recents(CONCEPT_RECENTS + CONCEPT_RECENTS_SEMEME, sememe_id, sememe_text, sememe_terminology_types)
        end

        render json: sememe
    end

    def get_generated_vhat_properties

        # if the generate vuid flag is true then we want to request new VUID IDs
        if user_session(UserSession::USER_PREFERENCES)[:generate_vuid] == 'true'
            generate_ids = true
        else
            generate_ids = false
        end

        render json: generate_vhat_properties(generate_ids)
    end

    def get_generated_vhat_ids
        vuids = request_vuids(params[:number_of_vuids], params[:reason])
        render json: vuids.to_json
    end

    def edit_concept

        concept_id =  params[:concept_id]
        failed_writes = []
        coordinates_token = session[:coordinates_token].token
        view_params = check_view_params(params[:view_params])
        view_params.delete('time')
        view_params.delete('allowedStates')
        additional_req_params = {}

        # this is a lambda to be used to process sememes nested under the concept and descriptions
        process_sememes = ->(referenced_id, sememes, type, error_text_prefix = '', referenced_temp_id = nil) {

            referenced_id_for_error = referenced_id

            if referenced_temp_id != nil
                referenced_id_for_error = referenced_temp_id
            end

            vhat_id_failed = false
            vhat_id_failed_error = nil

            sememes.each do |sememe_instance_id, sememe|

                begin

                    # get the sememe definition ID  and name
                    sememe_definition_id = sememe['sememe']
                    sememe_name = sememe['sememe_name']

                    # if there has already been a failed vhat ID processed for the referenced concept and this is another vhat ID, do not attempt to save
                    if vhat_id_failed && session[:komet_vhat_ids].include?(sememe_definition_id)

                        failed_writes << {id: referenced_id_for_error + '_' + sememe_instance_id, text: error_text_prefix + type + ': ' + sememe_name + ': ' + vhat_id_failed_error, type: type}
                        next
                    end

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
                    additional_req_params[:editToken] = get_edit_token

                    sememe.each do |field_id, field|
                        body_params[:columnData] << {columnNumber: field['column_number'], data: field['value'].strip, '@class' => field['data_type_class']}
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

                        failed_writes << {id: referenced_id_for_error + '_' + sememe_instance_id, text: error_text_prefix + type + ': ' + sememe_name + ': ' + return_value.rest_exception.conciseMessage, type: type}

                        # if this is a vhat ID flag that it failed and the error so we can mark any other vhat IDs the same
                        if session[:komet_vhat_ids].include?(sememe_definition_id)

                            vhat_id_failed = true
                            vhat_id_failed_error = return_value.rest_exception.conciseMessage
                        end
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
                                fsn: description['text'].strip,
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
                            additional_req_params[:editToken] = get_edit_token

                            new_concept_id = ConceptRest::get_concept(action: ConceptRestActions::ACTION_CREATE, additional_req_params: additional_req_params, body_params: body_params )

                            # if the concept create failed return with a failed message
                            if new_concept_id.is_a? CommonRest::UnexpectedResponse
                                render json: {concept_id: concept_id, failed: [{id: concept_id, text: 'Clone Concept: The new concept was unable to be created. ' + new_concept_id.rest_exception.conciseMessage , type: 'clone'}]} and return
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

            # if the concept create did not happen return with a failed message, otherwise copy the new concept ID into the concept_id field to continue with the edit
            if create_success
                concept_id = new_concept_id.uuid

                dialects_to_remove.each_with_index do |dialect, index|

                    fsn[:dialects][new_concept_id.dialectSememes[index].uuids.first] = dialect
                    fsn[:dialects].delete(dialect['dialect_id'])
                end

                # Copy the FSN into a new description entry using the returned ID from the newly created FSN, then delete the old key
                params[:descriptions][new_concept_id.fsnDescriptionSememe.uuids.first] = fsn
                params[:descriptions].delete(fsn_id)

            else
                render json: {concept_id: concept_id, failed: [{id: concept_id, text: 'Clone Concept: The new concept was unable to be created.', type: 'clone'}]} and return
            end
        end

        additional_req_params = {coordToken: coordinates_token}
        additional_req_params.merge!(view_params)

        if params[:concept_state]

            if params[:concept_state].downcase == 'active'
                active = true
            else
                active = false
            end

            additional_req_params[:editToken] = get_edit_token

            return_value = ComponentRest::get_component(action: ComponentRestActions::ACTION_UPDATE_STATE, uuid_or_id: concept_id, additional_req_params: {active: active}.merge(additional_req_params))

            # if the concept state change failed, mark it
            if return_value.is_a? CommonRest::UnexpectedResponse
                failed_writes << {id: concept_id, text: params[:concept_state] + ': ' + return_value.rest_exception.conciseMessage, type: 'concept'}
            end
        end

        if params[:properties]
            process_sememes.call(concept_id, params[:properties], 'concept property')
        end

        if params[:descriptions]

            params[:descriptions].each do |description_id, description|

                if description['description_state'].downcase == 'active'
                    active = true
                else
                    active = false
                end

                body_params = {
                    caseSignificanceConcept: description['description_case_significance'],
                    languageConcept: description['description_language'],
                    text: description['text'].strip,
                    descriptionTypeConcept:  description['description_type'], # $isaac_metadata_auxiliary['SYNONYM']['uuids'].first[:uuid],
                    extendedDescriptionTypeConcept: description['extended_description_type'],
                    active: active
                }

                # if there is no value for case significance then add the Not Sensitive value to the params
                if description['description_case_significance'] == ''
                    body_params[:caseSignificanceConcept] = $isaac_metadata_auxiliary['DESCRIPTION_NOT_CASE_SENSITIVE']['uuids'].first[:uuid]
                end

                # if the description ID is a UUID, then it is an existing description to be updated, otherwise it is a new description to be created
                if is_id?(description_id)

                    additional_req_params[:editToken] = get_edit_token

                    return_value = SememeRest::get_sememe(action: SememeRestActions::ACTION_DESCRIPTION_UPDATE, uuid_or_id: description_id, additional_req_params: additional_req_params, body_params: body_params)

                    # if the description create or update failed, mark it and skip to the next description. Do not process its dialects or properties.
                    if return_value.is_a? CommonRest::UnexpectedResponse

                        failed_writes << {id: description_id, text: description['text'] + ': ' + return_value.rest_exception.conciseMessage, type: 'description'}
                        next
                    end

                    # process the dialects
                    if description[:dialects]

                        description[:dialects].each do |dialect_id, dialect|

                            additional_req_params[:editToken] = get_edit_token

                            if is_id?(dialect_id)

                                if dialect['state'].downcase == 'active'
                                    active = true
                                else
                                    active = false
                                end

                                return_value = ComponentRest::get_component(action: ComponentRestActions::ACTION_UPDATE_STATE, uuid_or_id: dialect_id, additional_req_params: {active: active}.merge(additional_req_params))
                            else

                                body_params = {
                                    assemblageConcept: dialect['dialect'],
                                    referencedComponent: description_id,
                                    columnData: [{columnNumber: 0, data: dialect['acceptability'], '@class' => 'gov.vha.isaac.rest.api1.data.sememe.dataTypes.RestDynamicSememeUUID'}]
                                }

                                return_value = SememeRest::get_sememe(action: SememeRestActions::ACTION_SEMEME_CREATE, additional_req_params: additional_req_params, body_params: body_params)
                            end

                            # if the dialect create or update failed, mark it.
                            if return_value.is_a? CommonRest::UnexpectedResponse
                                failed_writes << {id: description_id + '_' + dialect_id, text: 'Description: ' + description['text'] + ' : dialect' + ': ' + return_value.rest_exception.conciseMessage, type: 'dialect'}
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
                    additional_req_params[:editToken] = get_edit_token

                    return_value = SememeRest::get_sememe(action: SememeRestActions::ACTION_DESCRIPTION_CREATE, additional_req_params: additional_req_params, body_params: body_params)

                    # if the description create or update failed, mark it and skip to the next description. Do not process its properties.
                    if return_value.is_a? CommonRest::UnexpectedResponse

                        failed_writes << {id: description_id, text: description['text'] + ': ' + return_value.rest_exception.conciseMessage, type: 'description'}
                        next
                    end

                    # store the description temp ID in case we need to display an error on the GUI which would reference it
                    temp_description_id = description_id
                    description_id = return_value.uuid
                end

                # process the properties
                if description[:properties]
                    process_sememes.call(description_id, description[:properties], 'description property', 'Description: ' + description['text'] + ' : ', temp_description_id)
                end

            end
        end

        if params[:associations]

            params[:associations].each do |association_id, association|

                body_params = {targetId: association['target']}
                additional_req_params[:editToken] = get_edit_token

                if association['association_state'].downcase == 'active'
                    body_params[:active] = true
                else
                    body_params[:active] = false
                end

                # if the association ID is a UUID, then it is an existing association to be updated, otherwise it is a new association to be created
                if is_id?(association_id)

                    return_value = AssociationRest::get_association(action: AssociationRestActions::ACTION_ITEM_UPDATE, uuid_or_id: association_id, additional_req_params: additional_req_params, body_params: body_params)

                    if return_value.is_a? CommonRest::UnexpectedResponse
                        failed_writes << {id: association_id, text: 'Association: ' + association['target_display'] + ': ' + return_value.rest_exception.conciseMessage, type: 'association'}
                    else
                        add_to_recents(CONCEPT_RECENTS + CONCEPT_RECENTS_ASSOCIATION, association['target'], association['target_display'], association['target_terminology_types'])
                    end
                else

                    body_params[:associationType] = association['association_type']
                    body_params[:sourceId] = concept_id

                    return_value = AssociationRest::get_association(action: AssociationRestActions::ACTION_ITEM_CREATE, additional_req_params: additional_req_params, body_params: body_params)

                    if return_value.is_a? CommonRest::UnexpectedResponse
                        failed_writes << {id: association_id, text: 'Association: ' + association['target_display'] + ': ' + return_value.rest_exception.conciseMessage, type: 'association'}
                    else
                        add_to_recents(CONCEPT_RECENTS + CONCEPT_RECENTS_ASSOCIATION, association['target'], association['target_display'], association['target_terminology_types'])
                    end
                end

                return_value
            end
        end

        if params[:remove]

            params[:remove].each do |remove_concept_id, value|

                additional_req_params[:editToken] = get_edit_token

                ComponentRest::get_component(action: ComponentRestActions::ACTION_UPDATE_STATE, uuid_or_id: remove_concept_id, additional_req_params: {active: false}.merge(additional_req_params))

                # if the concept state change failed, mark it
                if return_value.is_a? CommonRest::UnexpectedResponse
                    failed_writes << {id: remove_concept_id, text: 'inactivate' + ': ' + return_value.rest_exception.conciseMessage, type: 'inactivate'}
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

        # check to see if there were view_params and parse it if there were
        if params[:view_params] && params[:view_params] != ''
            params[:view_params] = JSON.parse(params[:view_params]);
        end

        view_params = check_view_params(params[:view_params], false);
        search_term = params[:term]
        concept_suggestions_data = []
        additional_req_params = {coordToken: coordinates_token, query: search_term, maxPageSize: 25, expand: 'referencedConcept', mergeOnConcept: true}
        additional_req_params.merge!(view_params)
        restrict_search = params[:restrict_search]
        restrict_module = params[:restrict_module]

        # only restict the search if the flag is set
        if restrict_search != nil && restrict_search != ''
            additional_req_params[:restrictTo] = restrict_search;
        end

        # only restict the search if the flag is set
        if restrict_search != nil && restrict_search != ''
            additional_req_params[:restrictTo] = restrict_search;
        end

        # get the search results
        results = SearchApis.get_search_api(action: ACTION_PREFIX, additional_req_params: additional_req_params)

        # add the output type param for the translate calls when we loop through the results
        additional_req_params[:outputType] = 'vuid'

        # loop through each search result to build the return array
        results.results.each do |result|

            label = result.referencedConcept.description

            # get the list of terminology type IDs and descriptions
            terminology_types = get_uuids_from_identified_objects(result.referencedConcept.terminologyTypes)
            terminology_type_descriptions = get_terminology_description_list_from_identified_objects(result.referencedConcept.terminologyTypes)

            label += ' (' + terminology_type_descriptions + ')'

            # if this is a VHAT concept add the VUID
            if terminology_types.include?($isaac_metadata_auxiliary['VHAT_MODULES']['uuids'].first[:uuid])

                terminology_id = IdAPIsRest.get_id(uuid_or_id: result.referencedConcept.identifiers.uuids.first, action: IdAPIsRestActions::ACTION_TRANSLATE, additional_req_params: {outputType: 'vuid', coordToken: coordinates_token}.merge!(view_params))

                unless terminology_id.is_a? CommonRest::UnexpectedResponse
                    label += ' (VUID: ' + terminology_id.value + ')'
                end
            end

            # TODO - remove the hard-coding of type to 'vhat' when the type flags are implemented in the REST APIs
            # build the return object for this search result and add it to our array
            concept_suggestions_data << {label: label, value: result.referencedConcept.identifiers.uuids.first, terminology_types: terminology_types, matching_text: result.matchText}
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

        # if the view params are already in the session put them into a variable for the GUI, otherwise set the default values for view params and other items
        if false #session[:default_view_params] && session[:view_params_changed] != true
            @view_params = session[:default_view_params].clone
        else

            # if the view params haven't changed then this is the first hit on the dashboard and we should set vars, otherwise we should updated them
            if session[:view_params_changed] != true

                # set variables for default view parameters that can be accessed from any controller or module
                @view_params = {stated: true, allowedStates: 'active,inactive', time: 'latest', modules: '', path: $isaac_metadata_auxiliary['DEVELOPMENT_PATH']['uuids'].first[:uuid]}
                session[:default_view_params] = @view_params.clone

                # set a variable for view params to be used when pulling data for edits, which should always be the least restricted possible
                session[:edit_view_params] = @view_params.clone

                # create the options for stated/inferred preference controls
                session[:komet_stated_options] = [['Stated', 'true'],['Inferred', 'false']]

                # create the options for stated/inferred preference controls
                session[:komet_allowed_states_options] = [['All', 'active,inactive'],['Active', 'active']]
                session[:komet_all_allowed_states_options] = [['All', 'active,inactive'],['Active', 'active'],['Inactive', 'inactive']]
            else

                # update variables for default view parameters that can be accessed from any controller or module
                @view_params = session[:default_view_params].clone

                session.delete(:view_params_changed)
            end

            session[:komet_module_options] = []
            session['komet_extended_description_types'] = {}

            # get the full list of modules
            module_list = get_direct_children(type: 'module', concept_id: $isaac_metadata_auxiliary['MODULE']['uuids'].first[:uuid], view_params: session[:edit_view_params])
            #module_list = get_concept_children(concept_id: $isaac_metadata_auxiliary['MODULE']['uuids'].first[:uuid], return_json: false, remove_semantic_tag: true, include_nested: true, view_params: session[:edit_view_params])

            # loop thru the full module list to build an array of options in the session, including the nested level of each module
            module_list.each do |komet_module|

                if komet_module[:text].nil?
                    komet_module[:text] = 'No Text'
                end

                indent = ('-' * komet_module[:level]) + ' '
                session[:komet_module_options] << [indent + komet_module[:text], komet_module[:concept_id], {title: komet_module[:text], 'data-level': komet_module[:level]}]

                # also build a list of the extended description types that apply to concepts belonging to this module
                extended_description_types = get_direct_children(type: 'extended description', concept_id: komet_module[:concept_id], include_nested: false, qualifier: komet_module[:text])
                #extended_description_types = get_extended_description_types(komet_module[:concept_id], true, false, {}, komet_module[:text])

                if extended_description_types.length > 0
                    session['komet_extended_description_types'][komet_module[:text].to_sym] = extended_description_types
                end
            end

            # get a list of regular description type options to be used if a concept module doesn't have extended type options
            session['komet_extended_description_types'][:default] = get_concept_children(concept_id: $isaac_metadata_auxiliary['DESCRIPTION_TYPE']['uuids'].first[:uuid], return_json: false, remove_semantic_tag: true, view_params: session[:edit_view_params])

            session[:komet_path_options] = []

            # get the full list of paths
            path_list = get_concept_children(concept_id: $isaac_metadata_auxiliary['PATH']['uuids'].first[:uuid], return_json: false, remove_semantic_tag: true, view_params: session[:edit_view_params])

            # loop thru the full path list to build an array of options in the session
            path_list.each do |path|
                session[:komet_path_options] << [path[:text], path[:concept_id]]
            end

            # get the list of taxonomy IDs and store them in the session
            session[:komet_taxonomy_ids] = []
            session[:komet_taxonomy_options] = []
            session[:komet_vhat_ids] = [$isaac_metadata_auxiliary['VUID']['uuids'].first[:uuid], $isaac_metadata_auxiliary['CODE']['uuids'].first[:uuid]]

            # get the user preferences from the session
            user_prefs = user_session(UserSession::USER_PREFERENCES)

            # if there are no user preferences create a new hash that treats Strings and Symbols the same, load it with user data, and save it in the session
            if user_prefs.nil?

                user_prefs = HashWithIndifferentAccess.new
                user_prefs[:generate_vuid] = 'false'
                user_session(UserSession::USER_PREFERENCES, user_prefs)
            end

            taxonomies = IdAPIsRest.get_id(action: IdAPIsRestActions::ACTION_IDS)

            # if the taxonomy results are not empty process them, otherwise build a short list from what is in the metadata
            if !taxonomies.is_a? CommonRest::UnexpectedResponse

                # loop thru the taxonomy results to build an array in the session TODO - remove the slice once the API no longer includes the semantic tag
                taxonomies.each do |taxonomy|

                    taxonomy.description.slice!(' (ISAAC)')
                    session[:komet_taxonomy_ids] << taxonomy.identifiers.uuids.first
                    session[:komet_taxonomy_options] << [taxonomy.description, taxonomy.identifiers.uuids.first]
                end
            else

                session[:komet_taxonomy_ids] = [$isaac_metadata_auxiliary['SCTID']['uuids'].first[:uuid], $isaac_metadata_auxiliary['VUID']['uuids'].first[:uuid], $isaac_metadata_auxiliary['CODE']['uuids'].first[:uuid]]
                session[:komet_taxonomy_options] = [['SCTID', $isaac_metadata_auxiliary['SCTID']['uuids'].first[:uuid]], ['VUID', $isaac_metadata_auxiliary['VUID']['uuids'].first[:uuid]]]
            end

            # if the taxonomy page size is not in the session set it to the default
            if !session[:komet_taxonomy_page_size]
                session[:komet_taxonomy_page_size] = 250
            end
        end

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

    def import
        body_string = read_xml_file
        vuid_generation = user_session(UserSession::USER_PREFERENCES)["generate_vuid"]

        additional_req_params = { 
            editToken: get_edit_token,
            vuidGeneration: vuid_generation
        }
        
        response = IntakeRest.get_intake(
                    action: IntakeRest::ACTION_VETS_XML, 
                    body_string: body_string, 
                    additional_req_params: additional_req_params
                   )  
        if response.respond_to? :flash_error
          clear_rest_caches
          render json: { 
            errors: { 
              status: response.status, 
              body: response.body, 
              message: response.rest_exception.conciseMessage 
            } 
          }, status: 422
        else 
          head :ok
        end
    end

  private
  def read_xml_file
    params[:file].tempfile.read
  end
end
