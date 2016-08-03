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

##
# MappingController -
# handles the concept mapping screens
class MappingController < ApplicationController
    include CommonController

    before_filter :init_session
    skip_before_filter :set_render_menu, :only => [:map_set_editor]


    def init_session

        if true #!session['map_set_data']

            session['map_tree_data'] = [{id: '1', set_id: '1', text: 'Set 1', icon: 'komet-tree-node-icon fa fa-folder', a_attr: {class: 'komet-context-menu', 'data-menu-type' => 'map_set', 'data-menu-uuid' => '1'}},
                                        {id: '2', set_id: '2', text: 'Set 2', icon: 'komet-tree-node-icon fa fa-folder', a_attr: {class: 'komet-context-menu', 'data-menu-type' => 'map_set', 'data-menu-uuid' => '2'}}]

            session['map_set_data'] = [{id: '1', name: 'Set 1', purpose: 'Test 1', description: 'Set 1 Description', review_state: 'Pending', status: 'Active', time: '10/10/2016', module: 'Development', path: 'Path'},
                                       {id: '2', name: 'Set 2', purpose: 'Test 2', description: 'Set 2 Description', review_state: 'Pending', status: 'Active', time: '10/10/2016', module: 'Development', path: 'Path'}]

            session['map_item_data'] = [{id: '1', set_id: '1', source: '11', source_display: 'Source 11', target: 'Target 11', target_display: 'Target 11', qualifier: 'No Qualifier', comments: 'This is a comment', review_state: 'Pending', status: 'Active', time: '10/10/2016', module: 'Development', path: 'Path'},
                                        {id: '2', set_id: '1', source: '12', source_display: 'Source 12', target: 'Target 12', target_display: 'Target 12', qualifier: 'No Qualifier', comments: 'This is a comment', review_state: 'Pending', status: 'Active', time: '10/10/2016', module: 'Development', path: 'Path'},
                                        {id: '3', set_id: '2', source: '21', source_display: 'Source 21', target: 'Target 21', target_display: 'Target 21', qualifier: 'No Qualifier', comments: 'This is a comment', review_state: 'Pending', status: 'Active', time: '10/10/2016', module: 'Development', path: 'Path'},
                                        {id: '4', set_id: '2', source: '22', source_display: 'Source 22', target: 'Target 22', target_display: 'Target 22', qualifier: 'No Qualifier', comments: 'This is a comment', review_state: 'Pending', status: 'Active', time: '10/10/2016', module: 'Development', path: 'Path'}]
        end

    end

    def load_tree_data

        text_filter = params[:text_filter]
        set_filter = params[:set_filter]
        mapping_tree = []

        session['map_set_data'].each do |set|
            mapping_tree << {id: get_next_id, set_id: set[:id], text: set[:name], icon: 'komet-tree-node-icon fa fa-folder', a_attr: {class: 'komet-context-menu', 'data-menu-type' => 'map_set', 'data-menu-uuid' => set[:id]}}
        end

        mapping_tree = [id: '0', set_id: '0', text: 'Mapping Sets', icon: 'komet-tree-node-icon fa fa-tree', children: mapping_tree, state: {opened: 'true'}]

        render json: mapping_tree

    end

    def load_mapping_viewer

        @set_id = params[:set_id]
        @item_id = params[:set_id]
        @viewer_title = 'Mapping Sets'
        @mapping_action = params[:mapping_action]
        @viewer_id =  params[:viewer_id]

        if @viewer_id == nil || @viewer_id == '' || @viewer_id == 'new'
            @viewer_id = get_next_id
        end

        if @mapping_action == 'set_details'
            map_set_editor
        end

        render partial: params[:partial]
    end

    def get_overview_sets_results

        coordinates_token = session[:coordinatestoken].token
        results = {}
        data = []
        filter = params[:overview_sets_filter]
        show_inactive = params[:show_inactive]
        page_size = 1000 #params[:overview_sets_page_size]
        page_number = 1 #params[:overview_sets_page_number]

        results[:total_number] = 4
        results[:page_number] = page_number

        results[:data] = session['map_set_data']
        render json: results
    end

    def map_set_editor

        if @set_id == nil
            @set_id = params[:set_id]
        end

        if @set_id

            @map_set = session['map_set_data'].select { |set|
                set[:id] == @set_id
            }.first
        else
            @map_set = {id: nil, name: nil, purpose: nil, description: nil, review_state: nil, status: 'No Status', time: nil, module: nil, path: nil}
        end
    end

    def get_overview_items_results

        coordinates_token = session[:coordinatestoken].token
        results = {}
        data = []
        set_id = params[:overview_set_id]
        filter = params[:overview_sets_filter]
        show_inactive = params[:show_inactive]
        page_size = 1000 #params[:overview_items_page_size]
        page_number = 1 #params[:overview_items_page_number]

        results[:total_number] = 2
        results[:page_number] = page_number

        matching_items = session['map_item_data'].select { |item|
            item[:set_id] == set_id.to_s
        }

        results[:data] = matching_items
        render json: results
    end

    def process_map_set

        set_id = params[:komet_mapping_set_editor_set_id]
        set_name = params[:komet_mapping_set_editor_name]
        purpose = params[:komet_mapping_set_editor_purpose]
        description = params[:komet_mapping_set_editor_description]
        review_state = params[:komet_mapping_set_editor_review_state]

        set = {name: set_name, purpose: purpose, description: description, review_state: review_state, status: 'Active', time: Time.now.strftime('%m/%d/%Y %H:%M'), module: 'Development', path: 'Path'}

        if set_id && set_id != ''

            array_id = session['map_set_data'].each_index.select { |index|
                session['map_set_data'][index][:id] == set_id.to_s
            }.first

            set[:id] = set_id

            session['map_set_data'][array_id] = set
        else

            set[:id] = (session['map_set_data'].last[:id].to_i + 1).to_s

            session['map_set_data'] << set
        end

        head :ok, content_type: 'text/html'

    end

    def map_item_editor

        set_id = params[:set_id]
        item_id = params[:item_id]

        if item_id

            @map_item = session['map_item_data'].select { |item|
                item[:id] == item_id
            }.first
        else
            @map_item = {id: nil, set_id: set_id, source: nil, source_display: nil, target: nil, target_display: nil, qualifier: 'No Qualifier', comments: nil, review_state: nil, status: 'Active', time: nil, module: nil, path: nil}
        end

        # get the list of advanced descriptions code_system
        @advanced_descriptions = [['No Restrictions', ''], ['Abbreviation', 'abbreviation']]

        # get the list of code systems
        @code_systems = [['No Restrictions', ''], ['SNOMED CT']]

        # get the list of assemblages
        @assemblages = [['No Restrictions', ''], ['SNOMED CT']]

    end

    def process_map_item

        item_id = params[:komet_mapping_item_editor_item_id]
        set_id = params[:komet_mapping_item_editor_set_id]
        source = params[:komet_mapping_item_editor_source]
        source_display = params[:komet_mapping_item_editor_source_display]
        target = params[:komet_mapping_item_editor_target]
        target_display = params[:komet_mapping_item_editor_target_display]
        qualifier = params[:komet_mapping_item_editor_qualifier]
        comments = params[:komet_mapping_item_editor_comments]
        review_state = params[:komet_mapping_item_editor_review_state]

        item = {set_id: set_id, source: source, source_display: source_display, target: target, target_display: target_display, qualifier: qualifier, comments: comments, review_state: review_state, status: 'Active', time: Time.now.strftime('%m/%d/%Y %H:%M'), module: 'Development', path: 'Path'}

        if item_id && item_id != ''

            array_id = session['map_item_data'].each_index.select { |index|
                session['map_item_data'][index][:id] == item_id.to_s
            }.first

            item[:id] = item_id

            session['map_item_data'][array_id] = item
        else

            item[:id] = (session['map_item_data'].last[:id].to_i + 1).to_s

            session['map_item_data'] << item
        end

        if source && source != ''
            add_to_recents(:mapping_item_source_recents, source, source_display)
        end

        if target && target != ''
            add_to_recents(:mapping_item_target_recents, target, target_display)
        end

        head :ok, content_type: 'text/html'

    end

    ##
    # get_item_source_suggestions - RESTful route for populating a list suggested list of concepts as a user types into a field via http :GET or :POST
    # The term entered by the user to search for source concepts with a request param of :term
    #@return [json] a list of matching concept text and ids - array of hashes {label:, value:}
    def get_item_source_suggestions

        coordinates_token = session[:coordinatestoken].token
        search_term = params[:term]
        suggestions_data = [{label: 'Concept 1', value: '123'}, {label: 'Concept 2', value: '456'}, {label: 'Concept 3', value: '789'}]

        #results = SearchApis.get_search_api(action: ACTION_PREFIX, additional_req_params: {coordToken: coordinates_token, query: search_term, maxPageSize: 25, expand: 'referencedConcept'})

        #results.results.each do |result|

        #assemblage_suggestions_data << {label: result.matchText, value: result.referencedConcept.identifiers.uuids.first}

        #end

        render json: suggestions_data
    end

    ##
    # get_item_source_recents - RESTful route for populating a list of recent source concepts searches via http :GET
    #@return [json] an array of hashes {id:, text:}
    def get_item_source_recents

        recents_array = []

        if session[:mapping_item_source_recents]
            recents_array = session[:mapping_item_source_recents]
        end

        render json: recents_array
    end

    ##
    # get_item_target_suggestions - RESTful route for populating a list suggested list of concepts as a user types into a field via http :GET or :POST
    # The term entered by the user to search for target concepts with a request param of :term
    #@return [json] a list of matching concept text and ids - array of hashes {label:, value:}
    def get_item_target_suggestions

        coordinates_token = session[:coordinatestoken].token
        search_term = params[:term]
        suggestions_data = [{label: 'Concept 1', value: '123'}, {label: 'Concept 2', value: '456'}, {label: 'Concept 3', value: '789'}]

        #results = SearchApis.get_search_api(action: ACTION_PREFIX, additional_req_params: {coordToken: coordinates_token, query: search_term, maxPageSize: 25, expand: 'referencedConcept'})

        #results.results.each do |result|

        #assemblage_suggestions_data << {label: result.matchText, value: result.referencedConcept.identifiers.uuids.first}

        #end

        render json: suggestions_data
    end

    ##
    # get_item_target_recents - RESTful route for populating a list of recent target concepts searches via http :GET
    #@return [json] an array of hashes {id:, text:}
    def get_item_target_recents

        recents_array = []

        if session[:mapping_item_target_recents]
            recents_array = session[:mapping_item_target_recents]
        end

        render json: recents_array
    end

    ##
    # get_item_kind_of_suggestions - RESTful route for populating a list suggested list of concepts as a user types into a field via http :GET or :POST
    # The term entered by the user to search for 'kind of' concepts with a request param of :term
    #@return [json] a list of matching concept text and ids - array of hashes {label:, value:}
    def get_item_kind_of_suggestions

        coordinates_token = session[:coordinatestoken].token
        search_term = params[:term]
        suggestions_data = [{label: 'Concept 1', value: '123'}, {label: 'Concept 2', value: '456'}, {label: 'Concept 3', value: '789'}]

        #results = SearchApis.get_search_api(action: ACTION_PREFIX, additional_req_params: {coordToken: coordinates_token, query: search_term, maxPageSize: 25, expand: 'referencedConcept'})

        #results.results.each do |result|

        #assemblage_suggestions_data << {label: result.matchText, value: result.referencedConcept.identifiers.uuids.first}

        #end

        render json: suggestions_data
    end

    ##
    # get_item_kind_of_recents - RESTful route for populating a list of recent 'kind of' concepts searches via http :GET
    #@return [json] an array of hashes {id:, text:}
    def get_item_kind_of_recents

        recents_array = []

        if session[:mapping_item_kind_of_recents]
            recents_array = session[:mapping_item_kind_of_recents]
        end

        render json: recents_array
    end

    def get_target_candidates_results

        coordinates_token = session[:coordinatestoken].token
        results = {}
        data = [{id: '1', concept: 'Test 1', code_system: 'SNOMED CT', status: 'Active'},
                {id: '2', concept: 'Test 2', code_system: 'LOINC', status: 'Active'}]
        search_text = params[:search_text]
        description_type = params[:description_type]
        advanced_description_type = params[:advanced_description_type]
        code_system = params[:code_system]
        assemblage = params[:assemblage]
        kind_of = params[:kind_of]
        page_size = 1000 #params[:page_size ]
        page_number = 1 #params[:page_number]

        results[:total_number] = 2
        results[:page_number] = page_number

        results[:data] = data
        render json: results
    end

end