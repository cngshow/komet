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
require 'bigdecimal'

include ERB::Util

##
# MappingController -
# handles the concept mapping screens
class MappingController < ApplicationController
    include ApplicationHelper, CommonController, TaxonomyHelper, ConceptConcern

    skip_before_filter :set_render_menu, :only => [:map_set_editor]
    before_action :can_edit_concept, only: [:process_map_set, :process_map_item]

    DATA_TYPES_CLASS = Gov::Vha::Isaac::Rest::Api1::Data::Sememe::DataTypes

    def load_tree_data

        coordinates_token = session[:coordinates_token].token
        text_filter = params[:text_filter]
        set_filter = params[:set_filter]
        view_params = check_view_params(params[:view_params])
        mapping_tree = []

        map_sets_results = MappingApis::get_mapping_api(action: MappingApiActions::ACTION_SETS,  additional_req_params: {coordToken: coordinates_token, CommonRest::CacheRequest => false}.merge!(view_params) )

        map_sets_results.each do |set|

            set_hash = {}

            flags = get_tree_node_flag('module', [set.mappingSetStamp.moduleSequence])
            flags << get_tree_node_flag('path', [set.mappingSetStamp.pathSequence])

            set_hash[:id] = get_next_id
            set_hash[:set_id] = set.identifiers.uuids.first
            set_hash[:text] = CGI::escapeHTML(set.name) + flags
            set_hash[:state] = set.mappingSetStamp.state.enumName
            # TODO - remove the hard-coding of type to 'vhat' when the type flags are implemented in the REST APIs
            set_hash[:terminology_type] = 'vhat'
            set_hash[:icon] = 'komet-tree-node-icon fa fa-folder'

            set_hash[:a_attr] = {class: 'komet-context-menu',
                                 'data-menu-type' => 'map_set',
                                 'data-menu-uuid' => set_hash[:set_id],
                                 'data-menu-concept-text' => set_hash[:text],
                                 'data-menu-state' => set_hash[:state],
                                 'data-menu-concept-terminology-type' => set_hash[:terminology_type]
            }

            if set_hash[:state].downcase.eql?('inactive')
                set_hash[:a_attr][:class] << ' komet-inactive-tree-node'
            end

            mapping_tree << set_hash
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
            @viewer_id = get_next_id.to_s
        end

        if @mapping_action == 'create_set' || @mapping_action == 'edit_set'
            @view_params = session[:edit_view_params]
        else
            @view_params = check_view_params(params[:view_params])
        end
        
        if @mapping_action == 'set_details' || @mapping_action == 'create_set' || @mapping_action == 'edit_set'
            map_set_editor
        end

        render partial: params[:partial]
    end

    def get_overview_sets_results

        coordinates_token = session[:coordinates_token].token
        results = {}
        data = []
        filter = params[:overview_sets_filter]
        show_inactive = params[:show_inactive]
        page_size = 1000 #params[:overview_sets_page_size]
        page_number = 1 #params[:overview_sets_page_number]
        view_params = check_view_params(params[:view_params])

        map_sets_results = MappingApis::get_mapping_api(action: MappingApiActions::ACTION_SETS,  additional_req_params: {coordToken: coordinates_token, CommonRest::CacheRequest => false}.merge!(view_params) )

        map_sets_results.each do |set|

            set_hash = {}

            set_hash[:set_id] = set.identifiers.uuids.first
            set_hash[:name] = set.name
            set_hash[:description] = set.description
            set_hash[:state] = set.mappingSetStamp.state.enumName
            set_hash[:time] = DateTime.strptime((set.mappingSetStamp.time / 1000).to_s, '%s').strftime('%m/%d/%Y')
            set_hash[:author] = get_concept_metadata(set.mappingSetStamp.authorSequence, view_params)
            set_hash[:module] = get_concept_metadata(set.mappingSetStamp.moduleSequence, view_params)
            set_hash[:path] = get_concept_metadata(set.mappingSetStamp.pathSequence, view_params)

            data << set_hash
        end

        results[:total_number] = data.length
        results[:page_number] = page_number

        results[:data] = data
        render json: results
    end

    def map_set_editor

        # reset the session item definitions
        session[:mapset_item_definitions] = []
        coordinates_token = session[:coordinates_token].token
        @map_set = {id: '', name: '', description: '', version: '', vuid: '', rules: '', include_fields: [], state: 'Active', time: '', module: '', path: '', comment_id: 0, comment: ''}
        source_system_id = $isaac_metadata_auxiliary['SOURCE_CODE_SYSTEM']['uuids'].first[:uuid]
        source_system_text = $isaac_metadata_auxiliary['SOURCE_CODE_SYSTEM']['fsn']
        source_version_id = $isaac_metadata_auxiliary['SOURCE_CODE_VERSION']['uuids'].first[:uuid]
        source_version_text = $isaac_metadata_auxiliary['SOURCE_CODE_VERSION']['fsn']
        target_system_id = $isaac_metadata_auxiliary['TARGET_CODE_SYSTEM']['uuids'].first[:uuid]
        target_system_text = $isaac_metadata_auxiliary['TARGET_CODE_SYSTEM']['fsn']
        target_version_id = $isaac_metadata_auxiliary['TARGET_CODE_VERSION']['uuids'].first[:uuid]
        target_version_text = $isaac_metadata_auxiliary['TARGET_CODE_VERSION']['fsn']
        description_id = $isaac_metadata_auxiliary['DESCRIPTION']['uuids'].first[:uuid]
        description_text = $isaac_metadata_auxiliary['DESCRIPTION']['fsn']


        # set the item field templates if they haven't already been set
        if session[:mapset_item_templates]
            @map_set[:item_templates] = session[:mapset_item_templates]
        else

            @map_set[:item_templates] = {IPO: [
                {id: $isaac_metadata_auxiliary['MAP_PATHWAY_ID']['uuids'].first[:uuid], description: $isaac_metadata_auxiliary['MAP_PATHWAY_ID']['fsn'], data_type: 'STRING', required: false, text: $isaac_metadata_auxiliary['MAP_PATHWAY_ID']['fsn'], removable: true, display: true, component_type: 'ITEM_EXTENDED'},
                {id: $isaac_metadata_auxiliary['VA_STATION_NUMBER']['uuids'].first[:uuid], description: $isaac_metadata_auxiliary['VA_STATION_NUMBER']['fsn'], data_type: 'STRING', required: false, text: $isaac_metadata_auxiliary['VA_STATION_NUMBER']['fsn'], removable: true, display: true, component_type: 'ITEM_EXTENDED'},
                {id: $isaac_metadata_auxiliary['VA_STATION_IEN']['uuids'].first[:uuid], description: $isaac_metadata_auxiliary['VA_STATION_IEN']['fsn'], data_type: 'STRING', required: false, text: $isaac_metadata_auxiliary['VA_STATION_IEN']['fsn'], removable: true, display: true, component_type: 'ITEM_EXTENDED'},
                {id: $isaac_metadata_auxiliary['CODE']['uuids'].first[:uuid], description: 'Source ' + $isaac_metadata_auxiliary['CODE']['fsn'], data_type: 'STRING', required: false, text: 'Source ' + $isaac_metadata_auxiliary['CODE']['fsn'], removable: true, display: true, component_type: 'SOURCE'},
                #{id: description_id, description: 'Source Description', data_type: 'STRING', required: false, text: 'Source Description', removable: true, display: true, component_type: 'SOURCE'},
                {id: $isaac_metadata_auxiliary['CODE']['uuids'].first[:uuid], description: 'Target ' + $isaac_metadata_auxiliary['CODE']['fsn'], data_type: 'STRING', required: false, text: 'Target ' + $isaac_metadata_auxiliary['CODE']['fsn'], removable: true, display: true, component_type: 'TARGET'},
                #{id: description_id, description: 'Target Description', data_type: 'STRING', required: false, text: 'Target Description', removable: true, display: true, component_type: 'TARGET'},
                {id: target_system_id, description: target_system_text, data_type: 'STRING', required: false, text: target_system_text, removable: true, display: true, component_type: 'ITEM_EXTENDED'},
                {id: target_version_id, description: target_version_text, data_type: 'STRING', required: false, text: target_version_text, removable: true, display: true, component_type: 'ITEM_EXTENDED'},
                {id: $isaac_metadata_auxiliary['TARGET_TERMINOLOGY_DATE']['uuids'].first[:uuid], description: $isaac_metadata_auxiliary['TARGET_TERMINOLOGY_DATE']['fsn'], data_type: 'STRING', required: false, text: $isaac_metadata_auxiliary['TARGET_TERMINOLOGY_DATE']['fsn'], removable: true, display: true, component_type: 'ITEM_EXTENDED'}
                #{id: $isaac_metadata_auxiliary['EQUIVALENCE_TYPE']['uuids'].first[:uuid], description: 'Relationship Type', data_type: 'STRING', required: false, text: 'Relationship Type', removable: true, display: true, component_type: 'ITEM_EXTENDED'},
            ]}

            session[:mapset_item_templates] = @map_set[:item_templates]
        end

        # set the Equivalence options if they haven't already been set
        if session[:mapset_equivalence_options]
            equivalence_options = session[:mapset_equivalence_options]
        else

            # get the options to populate the Equivalence Type dropdown
            equivalence_options = [{value: '', label: 'No Restrictions'}]

            get_direct_children($isaac_metadata_auxiliary['EQUIVALENCE_TYPES']['uuids'].first[:uuid], true, true, true, session[:edit_view_params]).each do |option|
                equivalence_options << {value: option[:concept_id], label: option[:text], tooltip: option[:definition]}
            end
        end

        @set_id = params[:set_id]

        if @set_id &&  @set_id != ''

            # add the definitions for the template map fields
            @map_set[:include_fields] = [source_system_id, source_version_id, target_system_id, target_version_id]

            set = MappingApis::get_mapping_api(action: MappingApiActions::ACTION_SET, uuid_or_id: @set_id,  additional_req_params: {coordToken: coordinates_token, expand: 'comments'}.merge!(@view_params))

            if set.is_a? CommonRest::UnexpectedResponse
                return @map_set
            end

            vuid = IdAPIsRest.get_id(uuid_or_id: @set_id, action: IdAPIsRestActions::ACTION_TRANSLATE, additional_req_params: {outputType: 'vuid'}.merge!(@view_params))

            if vuid.respond_to?(:value)
                @map_set[:vuid] = vuid.value
            else
                @map_set[:vuid] = ''
            end

            extended_fields = set.mapSetExtendedFields

            extended_fields.each do |field|

                id = field.extensionNameConceptIdentifiers.uuids.first
                text = field.extensionNameConceptDescription
                value = field.extensionValue.data
                removable = true
                display = true
                data_type = field.extensionValue.class.to_s.remove('Gov::Vha::Isaac::Rest::Api1::Data::Sememe::DataTypes::RestDynamicSememe')

                # if the field is business rules then pull it out and handle it specially
                if id == $isaac_metadata_auxiliary['BUSINESS_RULES']['uuids'].first[:uuid]

                    @map_set[:rules] = value
                    next
                end

                if value == nil && value == ''
                    display = false
                end

                if !@map_set[:include_fields].include?(id)
                    @map_set[:include_fields] << id
                end

                @map_set[id] = {id: id, data_type: data_type, value: html_escape(value), text: text, removable: removable, display: display, required: false}

                if field.extensionValue.class == DATA_TYPES_CLASS::RestDynamicSememeNid || field.extensionValue.class == DATA_TYPES_CLASS::RestDynamicSememeUUID

                    @map_set[id][:data_type] = 'UUID'

                    if display

                        if field.extensionValue.class == DATA_TYPES_CLASS::RestDynamicSememeNid
                            @map_set[id][:value] = IdAPIsRest.get_id(uuid_or_id: value, action: IdAPIsRestActions::ACTION_TRANSLATE, additional_req_params: {inputType: 'nid', outputType: 'uuid'}).value
                        end

                        @map_set[id.to_s + '_display'] = field.extensionValue.conceptDescription
                    end
                end

            end

            # remove any unused default included fields
            [source_system_id, source_version_id, target_system_id, target_version_id].each_with_index  do |field, index|

                if !@map_set.key?(field)
                    @map_set[:include_fields].delete(field)
                end
            end

            # if there are no values for displayFields follow the old way of sorting the fields, otherwise use displayFields to set order
            if set.displayFields.length == 0 
                
                # add the definitions for the template item fields
                @map_set[:item_fields] = [description_id + '_SOURCE', description_id + '_TARGET', description_id + '_EQUIVALENCE_TYPE']

                # setup the intrinsic map item fields
                source_info = {id: 'DESCRIPTION_SOURCE', description: 'Source ' + $isaac_metadata_auxiliary['DESCRIPTION']['fsn'], order: 0, data_type: 'UUID', required: true, text: 'Source ' + $isaac_metadata_auxiliary['DESCRIPTION']['fsn'], removable: false, display: true, component_type: 'SOURCE'}
                target_info = {id: 'DESCRIPTION_TARGET', description: 'Target ' + $isaac_metadata_auxiliary['DESCRIPTION']['fsn'], order: 1, data_type: 'UUID', required: true, text: 'Target ' + $isaac_metadata_auxiliary['DESCRIPTION']['fsn'], removable: false, display: true, component_type: 'TARGET'}
                qualifier_info = {id: 'DESCRIPTION_EQUIVALENCE_TYPE', description: $isaac_metadata_auxiliary['EQUIVALENCE_TYPE']['fsn'], order: 2, data_type: 'SELECT', required: true, text: $isaac_metadata_auxiliary['EQUIVALENCE_TYPE']['fsn'], removable: false, display: true, component_type: 'EQUIVALENCE_TYPE', options: equivalence_options, options_tooltip: true}

                # load the intrinsic map item fields into our return mapset variable
                @map_set['item_field_' + description_id + '_SOURCE'] = source_info
                @map_set['item_field_' + description_id + '_TARGET'] = target_info
                @map_set['item_field_' + description_id + '_EQUIVALENCE_TYPE'] = qualifier_info

                # load the intrinsic map item fields into our session item definitions
                session[:mapset_item_definitions] = [source_info, target_info, qualifier_info]

                # get the item fields from the mapset
                item_fields = set.mapItemFieldsDefinition

                # loop through the item extended fields
                item_fields.each do |field|
    
                    id = field.columnLabelConcept.uuids.first
                    text = field.columnName
                    description = field.columnDescription
                    order = field.columnOrder.to_s
                    data_type = field.columnDataType.enumName
                    required = field.columnRequired
                    removable = true
                    display = true
    
                    if data_type == 'LONG' && text.downcase.include?('date')
                        text << ' (mm/dd/yyyy)'
                    end
    
                    @map_set[:item_fields] << id + '_ITEM_EXTENDED'
                    @map_set['item_field_' + id + '_ITEM_EXTENDED'] = {id: id, description: description, order: order, data_type: data_type, required: required, text: text, removable: removable, display: display, component_type: 'ITEM_EXTENDED'}
    
                    session[:mapset_item_definitions] << @map_set['item_field_' + id + '_ITEM_EXTENDED']
    
                end
            else

                # add the definitions for the template item fields
                @map_set[:item_fields] = []
                field_info = {}
                computed_field_index = 0

                # item_fields.each do |field|
                set.displayFields.each do |field|

                    # handle the Mapping Source Concept
                    if field.id == description_id && field.componentType.enumName == 'SOURCE'

                        @map_set[:item_fields] << description_id + '_SOURCE'
                        field_info = {id: 'DESCRIPTION_SOURCE', description: 'Source ' + $isaac_metadata_auxiliary['DESCRIPTION']['fsn'], order: computed_field_index, data_type: 'UUID', required: true, text: 'Source ' + $isaac_metadata_auxiliary['DESCRIPTION']['fsn'], removable: false, display: true, component_type: 'SOURCE'}
                        @map_set['item_field_' + description_id + '_SOURCE'] = field_info
                        computed_field_index += 1
                    
                    # handle the Mapping Target Concept    
                    elsif field.id == description_id && field.componentType.enumName == 'TARGET'

                        @map_set[:item_fields] << description_id + '_TARGET'
                        field_info = {id: 'DESCRIPTION_TARGET', description: 'Target ' + $isaac_metadata_auxiliary['DESCRIPTION']['fsn'], order: computed_field_index, data_type: 'UUID', required: true, text: 'Target ' + $isaac_metadata_auxiliary['DESCRIPTION']['fsn'], removable: false, display: true, component_type: 'TARGET'}
                        @map_set['item_field_' + description_id + '_TARGET'] = field_info
                        computed_field_index += 1

                    # handle the Mapping Target Qualifier    
                    elsif field.id == description_id && field.componentType.enumName == 'EQUIVALENCE_TYPE'

                        @map_set[:item_fields] << description_id + '_EQUIVALENCE_TYPE'
                        field_info = {id: 'DESCRIPTION_EQUIVALENCE_TYPE', description: $isaac_metadata_auxiliary['EQUIVALENCE_TYPE']['fsn'], order: computed_field_index, data_type: 'SELECT', required: true, text: $isaac_metadata_auxiliary['EQUIVALENCE_TYPE']['fsn'], removable: false, display: true, component_type: 'EQUIVALENCE_TYPE', options: equivalence_options, options_tooltip: true}
                        @map_set['item_field_' + description_id + '_EQUIVALENCE_TYPE'] = field_info
                        computed_field_index += 1

                    # handle calculated fields    
                    elsif field.componentType.enumName == 'SOURCE' || field.componentType.enumName == 'TARGET'

                        @map_set[:item_fields] << field.id + '_' + field.componentType.enumName
                        field_info = {id: field.id, description: field.description, order: computed_field_index, data_type: 'STRING', required: false, text: field.description, removable: true, display: true, component_type: field.componentType.enumName}
                        @map_set['item_field_' + field.id + '_' + field.componentType.enumName] = field_info
                        computed_field_index += 1
                        
                    # handle extended fields    
                    else

                        extended_field = set.mapItemFieldsDefinition[field.id.to_i]

                        id = extended_field.columnLabelConcept.uuids.first
                        text = extended_field.columnName
                        description = extended_field.columnDescription
                        order = extended_field.columnOrder.to_s
                        data_type = extended_field.columnDataType.enumName
                        required = extended_field.columnRequired
                        removable = true
                        display = true

                        if data_type == 'LONG' && text.downcase.include?('date')
                            text << ' (mm/dd/yyyy)'
                        end

                        @map_set[:item_fields] << id + '_ITEM_EXTENDED'
                        field_info = {id: id, description: description, order: order, data_type: data_type, required: required, text: text, removable: removable, display: display, component_type: 'ITEM_EXTENDED'}
                        @map_set['item_field_' + id + '_ITEM_EXTENDED'] = field_info

                    end
                    
                    session[:mapset_item_definitions] << field_info
                end
   
            end
            
            @map_set[:set_id] = set.identifiers.uuids.first
            @map_set[:name] = html_escape(set.name)
            @map_set[:description] = html_escape(set.description)
            @map_set[:state] = set.mappingSetStamp.state.enumName
            @map_set[:time] = DateTime.strptime((set.mappingSetStamp.time / 1000).to_s, '%s').strftime('%m/%d/%Y')
            @map_set[:author] = get_concept_metadata(set.mappingSetStamp.authorSequence, @view_params)
            @map_set[:module] = get_concept_metadata(set.mappingSetStamp.moduleSequence, @view_params)
            @map_set[:path] = get_concept_metadata(set.mappingSetStamp.pathSequence, @view_params)

            if set.comments.length == 0
                @map_set[:comment] = ''
                @map_set[:comment_id] = '0'
            else
                @map_set[:comment] = html_escape(set.comments.first.comment)
                @map_set[:comment_id] = set.comments.first.identifiers.uuids.first
            end

            @viewer_title = @map_set[:name]

            @map_items = get_overview_items_results(@map_set[:set_id])
        else

            @mapping_action = 'create_set'
            @viewer_title = 'Create New Map Set'

            # add the definitions for the template map fields
            @map_set[:include_fields] = [source_system_id, source_version_id, target_system_id, target_version_id]
            @map_set[source_system_id] = {id: source_system_id, data_type: 'UUID', value: '', text: source_system_text, removable: false, display: false, required: false}
            @map_set[source_system_id + '_display'] = ''
            @map_set[source_version_id] = {id: source_version_id, data_type: 'STRING', value: '', text: source_version_text, removable: false, display: false, required: false}
            @map_set[target_system_id] = {id: target_system_id, data_type: 'UUID', value: '', text: target_system_text, removable: false, display: false, required: false}
            @map_set[target_system_id + '_display'] = ''
            @map_set[target_version_id] = {id: target_version_id, data_type: 'STRING', value: '', text: target_version_text, removable: false, display: false, required: false}

            # add the definitions for the template item fields
            @map_set[:item_fields] = [description_id + '_SOURCE', description_id + '_TARGET', description_id + '_EQUIVALENCE_TYPE']

            # setup the intrinsic map item fields
            source_info = {id: 'DESCRIPTION_SOURCE', description: 'Source ' + $isaac_metadata_auxiliary['DESCRIPTION']['fsn'], order: nil, data_type: 'UUID', required: true, text: 'Source ' + $isaac_metadata_auxiliary['DESCRIPTION']['fsn'], removable: false, display: true, component_type: 'SOURCE'}
            target_info = {id: 'DESCRIPTION_TARGET', description: 'Target ' + $isaac_metadata_auxiliary['DESCRIPTION']['fsn'], order: nil, data_type: 'UUID', required: true, text: 'Target ' + $isaac_metadata_auxiliary['DESCRIPTION']['fsn'], removable: false, display: true, component_type: 'TARGET'}
            qualifier_info = {id: 'DESCRIPTION', description: $isaac_metadata_auxiliary['EQUIVALENCE_TYPE']['fsn'], order: nil, data_type: 'SELECT', required: true, text: $isaac_metadata_auxiliary['EQUIVALENCE_TYPE']['fsn'], removable: false, display: true, component_type: 'EQUIVALENCE_TYPE', options: equivalence_options, options_tooltip: true}

            # load the intrinsic map item fields into our return mapset variable
            @map_set['item_field_' + description_id + '_SOURCE'] = source_info
            @map_set['item_field_' + description_id + '_TARGET'] = target_info
            @map_set['item_field_' + description_id + '_EQUIVALENCE_TYPE'] = qualifier_info

            # load the intrinsic map item fields into our session item definitions
            session[:mapset_item_definitions] = [source_info, target_info, qualifier_info]
        end

        # Get the complete list of available calculated fields
        calculated_fields = MappingApis::get_mapping_api(action: MappingApiActions::ACTION_FIELDS,  additional_req_params: {coordToken: coordinates_token}.merge!(session[:edit_view_params]))

        @map_set[:all_calculated_fields] = []

        unless calculated_fields.is_a? CommonRest::UnexpectedResponse

            calculated_fields.each do |calculated_field|

                # if the field is not an intrinsic (description) map field add it to the list of calculated field
                unless calculated_field.id == description_id

                    @map_set[:all_calculated_fields] << {id: calculated_field.id, component_type: 'SOURCE', text: 'Source ' + calculated_field.description}
                    @map_set[:all_calculated_fields] << {id: calculated_field.id, component_type: 'TARGET', text: 'Target ' + calculated_field.description}
                end

            end
        end

    end

    def get_overview_items_results(set_id = nil)

        coordinates_token = session[:coordinates_token].token
        column_definitions = session[:mapset_item_definitions]
        render_return = false
        view_params = params[:view_params]


        if set_id == nil && params[:set_id]

            render_return = true
            set_id = params[:set_id]
        end

        #filter = params[:overview_sets_filter]
        #show_inactive = params[:show_inactive]
        results = {column_definitions: column_definitions}
        item_data = []
        source_name = ''
        target_name = ''

        items = MappingApis::get_mapping_api(action: MappingApiActions::ACTION_ITEMS, uuid_or_id: set_id,  additional_req_params: {coordToken: coordinates_token, expand: 'referencedDetails, comments'}.merge!(view_params)) # CommonRest::CacheRequest => false

        if items.is_a? CommonRest::UnexpectedResponse
            return {total_number: 0, data: []}
        end

        items.each do |item|

            item_hash = {}
            source_name = ''
            target_name = ''

            item_hash[:item_id] = item.identifiers.uuids.first
            item_hash[:state] = item.mappingItemStamp.state.enumName
            item_hash[:time] = DateTime.strptime((item.mappingItemStamp.time / 1000).to_s, '%s').strftime('%m/%d/%Y')
            item_hash[:author] = get_concept_metadata(item.mappingItemStamp.authorSequence, view_params)
            item_hash[:module] = get_concept_metadata(item.mappingItemStamp.moduleSequence, view_params)
            item_hash[:path] = get_concept_metadata(item.mappingItemStamp.pathSequence, view_params)

            if item.comments.length == 0
                item_hash[:comment] = ''
                item_hash[:comment_id] = '0'
            else
                item_hash[:comment] = html_escape(item.comments.first.comment)
                item_hash[:comment_id] = item.comments.first.identifiers.uuids.first
            end

            # loop through the column definitions which are ordered properly
            column_definitions.each do |column_definition|

                # handle Mapping Source Concept, Mapping Target Concept, or Mapping Qualifier
                if column_definition[:id].starts_with?('DESCRIPTION')

                    # get the property that contains the field value
                    if column_definition[:id] == 'DESCRIPTION_EQUIVALENCE_TYPE'
                        item_hash[column_definition[:id]] = item.qualifierConcept

                    elsif column_definition[:id] == 'DESCRIPTION_SOURCE'
                        item_hash[column_definition[:id]] = item.sourceConcept
                    else
                        item_hash[column_definition[:id]] = item.targetConcept
                    end

                    # check to see if there is a value in the field before proceeding
                    if item_hash[column_definition[:id]] != nil && item_hash[column_definition[:id]] != ''
                        item_hash[column_definition[:id]] = item_hash[column_definition[:id]].uuids.first
                    else
                        item_hash[column_definition[:id]] = ''
                    end

                    # check to see if computedDisplayFields is present, otherwise just use the UUID for the value
                    if item.computedDisplayFields

                        item_hash[column_definition[:id] + '_display'] = item.computedDisplayFields[column_definition[:order].to_i].value

                        # if this is the source or target concept record the display name in the return object for convenient access since these columns aren't always in a predefined order
                        if column_definition[:id] == 'DESCRIPTION_SOURCE'
                            source_name = item.computedDisplayFields[column_definition[:order].to_i].value
                        elsif column_definition[:id] == 'DESCRIPTION_TARGET' && item.computedDisplayFields[column_definition[:order].to_i].value != nil
                            target_name = item.computedDisplayFields[column_definition[:order].to_i].value
                        end
                    else
                        item_hash[column_definition[:id] + '_display'] = item_hash[column_definition[:id]]
                    end

                # handle the calculated fields
                elsif ['SOURCE', 'TARGET'].include?(column_definition[:component_type])

                    item_hash[column_definition[:id]] = item.computedDisplayFields[column_definition[:order].to_i].value

                # handle extended field definitions
                else

                    # get the extended field column order from the definition so we can process the correct item from mapItemExtendedFields
                    field = item.mapItemExtendedFields[column_definition[:order].to_i]

                    # if there is no field data skip to the next column
                    if field == nil
                        next
                    end

                    # TODO - look into GEM mappings having data type and field data that doesn't match (GEM PCS ICD-10 to ICD-9)
                    # for UUID data types we need a display field
                    if column_definition[:data_type] == 'UUID'

                        if field.respond_to? :conceptDescription
                            item_hash[column_definition[:id] + '_display'] = field.conceptDescription
                        else
                            item_hash[column_definition[:id] + '_display'] = field.data
                        end
                    end

                    # if we are dealing with a date make sure to process it properly, otherwise just escape the data and then add it to our item hash
                    if column_definition[:data_type] == 'LONG' && column_definition[:text].downcase.include?('date')
                        item_hash[column_definition[:id]] = DateTime.strptime(field.data.to_s, '%Q').strftime('%m/%d/%Y')
                    else
                        item_hash[column_definition[:id]] = html_escape(field.data)
                    end
                end

                # record the item display name in the item hash for convenient access since these columns aren't always in a predefined order
                item_hash[:item_name] = source_name + ' - ' + target_name
            end

            item_data << item_hash
        end

        results[:total_number] = items.length
        results[:data] = item_data

        if render_return
            render json: results and return
        else
            return results
        end
    end

    def process_map_set

        set_id = params[:komet_mapping_set_editor_set_id]
        set_name = params[:komet_mapping_set_editor_name]
        description = params[:komet_mapping_set_editor_description]
        field_info = session[:mapset_item_definitions]
        failed_writes = {set: [], items: []}
        successful_writes = 0
        description_id = $isaac_metadata_auxiliary['DESCRIPTION']['uuids'].first[:uuid]

        begin

            if params[:komet_mapping_set_editor_state].downcase == 'active'
                active = true
            else
                active = false
            end

            body_params = {name: set_name, description: description, active: active}
            request_params = {editToken: get_edit_token}

            set_extended_fields = []
            item_extended_fields = []
            item_display_fields = []

            if params['komet_mapping_set_editor_include_fields'] != nil

                params['komet_mapping_set_editor_include_fields'].each do |set_field|

                    set_field_label = params['komet_mapping_set_editor_include_fields_' + set_field + '_label']
                    set_field_data_type = params['komet_mapping_set_editor_include_fields_' + set_field + '_data_type']

                    if set_field_data_type != 'UUID'
                        set_field_data_type = set_field_data_type.downcase
                        set_field_data_type[0] = params['komet_mapping_set_editor_include_fields_' + set_field + '_data_type'][0]
                    end

                    set_field_data_type = 'gov.vha.isaac.rest.api1.data.sememe.dataTypes.RestDynamicSememe' + set_field_data_type
                    set_field_value = params['komet_mapping_set_editor_' + set_field]

                    set_extended_fields << {extensionNameConcept: set_field_label, extensionValue: {'@class' => set_field_data_type, columnNumber: 1, data: set_field_value}}
                end
            end

            if params[:komet_mapping_set_editor_rules] != ''

                rules_id = $isaac_metadata_auxiliary['BUSINESS_RULES']['uuids'].first[:uuid]
                set_extended_fields << {extensionNameConcept: rules_id, extensionValue: {'@class' => 'gov.vha.isaac.rest.api1.data.sememe.dataTypes.RestDynamicSememeString', columnNumber: 1, data: params[:komet_mapping_set_editor_rules]}}
            end

            body_params[:mapSetExtendedFields] = set_extended_fields

            if set_id && set_id != ''

                return_value =  MappingApis::get_mapping_api(uuid_or_id: set_id, action: MappingApiActions::ACTION_UPDATE_SET, additional_req_params: request_params, body_params: body_params)

                if return_value.is_a? CommonRest::UnexpectedResponse
                    failed_writes[:set] << {id: :set, error: 'The set was unable to be updated.'}
                else
                    successful_writes += 1
                end
            else


                if params['komet_mapping_set_editor_items_include_fields'] != nil

                    extended_field_count = 0

                    params['komet_mapping_set_editor_items_include_fields'].each do |item_field|

                        item_field_label = params['komet_mapping_set_editor_items_include_fields_' + item_field + '_label']
                        item_field_data_type = params['komet_mapping_set_editor_items_include_fields_' + item_field + '_data_type']
                        item_field_component_type = params['komet_mapping_set_editor_items_include_fields_' + item_field + '_component_type']
                        item_field_required = params['komet_mapping_set_editor_items_include_fields_' + item_field + '_required']

                        if ['SOURCE', 'TARGET', 'EQUIVALENCE_TYPE'].include?(item_field_component_type)

                            if item_field_label.starts_with?('DESCRIPTION')
                                item_field_label = description_id
                            end

                        else

                            item_extended_fields << {columnLabelConcept: item_field_label, columnDataType: item_field_data_type, columnRequired: item_field_required}
                            item_field_label = extended_field_count
                            extended_field_count += 1
                        end

                        item_display_fields << {id: item_field_label, fieldComponentType: item_field_component_type}
                    end

                    body_params[:mapItemExtendedFieldsDefinition] = item_extended_fields
                    body_params[:displayFields] = item_display_fields
                end

                return_value = MappingApis::get_mapping_api(action: MappingApiActions::ACTION_CREATE_SET, additional_req_params: request_params, body_params: body_params )

                if return_value.is_a? CommonRest::UnexpectedResponse

                    failed_writes[:set] << {id: :set, error: 'The set was unable to be created.'}
                    render json: {set_id: nil, failed: failed_writes} and return
                end

                successful_writes += 1
                set_id = return_value.uuid
            end

            comment = params[:komet_mapping_set_editor_comment]
            comment_id = params[:komet_mapping_set_editor_comment_id]
            comment_return = ''

            if comment_id == '0' && comment != ''

                comment_return = CommentApis.get_comment_api(action: CommentApiActions::ACTION_CREATE, additional_req_params: {editToken: get_edit_token}, body_params: {comment: comment, commentedItem: set_id})

            elsif comment_id != '0'

                comment_return = CommentApis.get_comment_api(uuid_or_id: comment_id, action: CommentApiActions::ACTION_UPDATE, additional_req_params: {editToken: get_edit_token}, body_params: {comment: comment})
            end

            if comment_return.is_a? CommonRest::UnexpectedResponse

                if failed_writes[:set].length == 0
                    failed_writes[:set] << {id: :set, error: 'The comment was not successfully processed.'}
                else
                    failed_writes[:set][0][:error] << ' The comment was not successfully processed.'
                end

            elsif comment_return != ''
                successful_writes += 1
            end

        rescue => exception

            $log.error(exception)

            if failed_writes[:set].length == 0
                failed_writes[:set] << {id: :set, error: 'An error occurred. All data may not have been saved'}
            else
                failed_writes[:set][0][:error] << ' An error occurred. All data may not have been saved'
            end

            render json: {set_id: nil, failed: failed_writes} and return
        end

        if params[:items]

            params[:items].each do |item_id, item|

                begin

                    source_concept = nil
                    target_concept = nil
                    qualifier_concept = nil

                    if item['state'].downcase == 'active'
                        active = true
                    else
                        active = false
                    end



                    if item['qualifier_concept'] != nil && item['qualifier_concept'] != ''
                        qualifier_concept = item['qualifier_concept']
                    end

                    extended_fields = []

                    field_info.each do |field|

                        data_type = field[:data_type]
                        data = item[field[:id]]

                        if field[:id].starts_with?('DESCRIPTION')

                            if data == nil && data == ''
                                next
                            end

                            if field[:id] == 'DESCRIPTION_SOURCE'
                                source_concept = data
                            elsif field[:id] == 'DESCRIPTION_TARGET'
                                target_concept = data
                            else
                                qualifier_concept = data
                            end

                            next

                        elsif field[:component_type] == 'SOURCE' || field[:component_type] == 'TARGET'
                            next

                        elsif data_type != 'UUID'

                            if ['FLOAT', 'DOUBLE'].include?(data_type)
                                data = BigDecimal.new(data);

                            elsif ['LONG', 'INTEGER'].include?(data_type)

                                if data_type == 'LONG' && field[:text].downcase.include?('date') && data.include?('/')
                                    data = DateTime.strptime(data, '%m/%d/%Y').strftime('%Q')
                                end

                                if data == nil || data == ''
                                    data = nil
                                else
                                    data = data.to_i
                                end

                            elsif data_type == 'BOOLEAN'

                                if data == 'true'
                                    data = true
                                else
                                    data = false
                                end
                            end

                            data_type = data_type.downcase
                            data_type[0] = field[:data_type][0]
                        end

                        data_type = 'gov.vha.isaac.rest.api1.data.sememe.dataTypes.RestDynamicSememe' + data_type

                        extended_fields << {columnNumber: field[:order], data: data, '@class' => data_type}
                    end

                    body_params = {targetConcept: target_concept, qualifierConcept: qualifier_concept, mapItemExtendedFields: extended_fields, active: active}
                    item_error = ''

                    # if the item ID is a UUID, then it is an existing item to be updated, otherwise it is a new item to be created
                    if is_id?(item_id)

                        return_value = MappingApis::get_mapping_api(action: MappingApiActions::ACTION_UPDATE_ITEM, uuid_or_id: item_id, additional_req_params: {editToken: get_edit_token}, body_params: body_params)

                        if return_value.is_a? CommonRest::UnexpectedResponse
                            item_error << 'The map item below was not updated. '
                        else
                            successful_writes += 1
                        end
                    else

                        body_params[:mapSetConcept] = set_id
                        body_params[:sourceConcept] = source_concept

                        return_value = MappingApis::get_mapping_api(action: MappingApiActions::ACTION_CREATE_ITEM, additional_req_params: {editToken: get_edit_token}, body_params: body_params)

                        if return_value.is_a? CommonRest::UnexpectedResponse
                            item_error << 'The map item below was not created. '
                        else

                            successful_writes += 1
                            item_id = return_value.uuid
                        end
                    end

                    if !return_value.is_a? CommonRest::UnexpectedResponse

                        comment = item[:comment]
                        comment_id = item[:comment_id]
                        comment_return = ''

                        if comment_id == '0' && comment != ''

                            comment_return = CommentApis.get_comment_api(action: CommentApiActions::ACTION_CREATE, additional_req_params: {editToken: get_edit_token}, body_params: {comment: comment, commentedItem: item_id})

                        elsif comment_id != '0'

                            comment_return = CommentApis.get_comment_api(uuid_or_id: comment_id, action: CommentApiActions::ACTION_UPDATE, additional_req_params: {editToken: get_edit_token}, body_params: {comment: comment})
                        end

                        if comment_return.is_a? CommonRest::UnexpectedResponse
                            item_error << 'The comment on the map item below was not processed.'
                        else
                            successful_writes += 1
                        end
                    end

                    if item_error != ''
                        failed_writes[:items] << {id: item_id, error: item_error}
                    end

                rescue => exception

                    $log.error(exception)
                    failed_writes[:items] << {id: item_id, error: 'An error occurred, the data may not have been saved'}
                end
            end
        end

        # clear taxonomy caches after writing data
        if successful_writes > 0
            clear_rest_caches
        end

        render json: {set_id: set_id, failed: failed_writes}
    end

end