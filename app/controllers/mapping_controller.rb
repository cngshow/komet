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

##
# MappingController -
# handles the concept mapping screens
class MappingController < ApplicationController
    include ApplicationHelper, CommonController, TaxonomyHelper, ConceptConcern

    skip_before_filter :set_render_menu, :only => [:map_set_editor]
    before_action :can_edit_concept, only: [:process_map_set, :process_map_item]

    DATA_TYPES_CLASS = Gov::Vha::Isaac::Rest::Api1::Data::Sememe::DataTypes

    def load_tree_data

        coordinates_token = session[:coordinatestoken].token
        text_filter = params[:text_filter]
        set_filter = params[:set_filter]
        view_params = params[:view_params]
        mapping_tree = []

        map_sets_results = MappingApis::get_mapping_api(action: MappingApiActions::ACTION_SETS,  additional_req_params: {coordToken: coordinates_token, allowedStates: view_params['statesToView'], CommonRest::CacheRequest => false} )

        map_sets_results.each do |set|

            set_hash = {}

            flags = get_tree_node_flag('module', [set.mappingSetStamp.moduleSequence])
            flags << get_tree_node_flag('path', [set.mappingSetStamp.pathSequence])

            set_hash[:id] = get_next_id
            set_hash[:set_id] = set.identifiers.uuids.first
            set_hash[:text] = set.name + flags
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
        @view_params = params[:view_params]

        if @view_params == nil
            @view_params = {statesToView: 'active,inactive'}
        end

        if @viewer_id == nil || @viewer_id == '' || @viewer_id == 'new'
            @viewer_id = get_next_id.to_s
        end

        if @mapping_action == 'set_details' || @mapping_action == 'create_set' || @mapping_action == 'edit_set'
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
        view_params = params[:view_params]

        map_sets_results = MappingApis::get_mapping_api(action: MappingApiActions::ACTION_SETS,  additional_req_params: {coordToken: coordinates_token, allowedStates: view_params['statesToView'], CommonRest::CacheRequest => false} )

        map_sets_results.each do |set|

            set_hash = {}

            set_hash[:set_id] = set.identifiers.uuids.first
            set_hash[:name] = set.name
            set_hash[:description] = set.description
            set_hash[:state] = set.mappingSetStamp.state.enumName
            set_hash[:time] = DateTime.strptime((set.mappingSetStamp.time / 1000).to_s, '%s').strftime('%m/%d/%Y')
            set_hash[:author] = get_concept_metadata(set.mappingSetStamp.authorSequence)
            set_hash[:module] = get_concept_metadata(set.mappingSetStamp.moduleSequence)
            set_hash[:path] = get_concept_metadata(set.mappingSetStamp.pathSequence)

            data << set_hash
        end

        results[:total_number] = data.length
        results[:page_number] = page_number

        results[:data] = data
        render json: results
    end

    def map_set_editor

        session[:mapset_item_definitions] = []
        coordinates_token = session[:coordinatestoken].token
        @map_set = {id: '', name: '', description: '', version: '', vuid: '', rules: '', include_fields: [], state: '', status: 'Active', time: '', module: '', path: '', comment_id: 0, comment: ''}

        # add the definitions for the template map fields
        @map_set[:include_fields] = ['source_system', 'source_version', 'target_system', 'target_version']
        @map_set[:source_system] = {name: 'source_system', data_type: 'UUID', value: '', label: '32e30e80-3fac-5317-80cf-d85eab22fa9e', label_display: 'mapping source code system', removable: false, display: false, required: false}
        @map_set[:source_system_display] = ''
        @map_set[:source_version] = {name: 'source_version', data_type: 'STRING', value: '', label: '5b3479cb-25b2-5965-a031-54238588218f', label_display: 'mapping source code system version', removable: false, display: false, required: false}
        @map_set[:target_system] = {name: 'target_system', data_type: 'UUID', value: '', label: '6b31a67a-7e6d-57c0-8609-52912076fce8', label_display: 'mapping target code system', removable: false, display: false, required: false}
        @map_set[:target_system_display] = ''
        @map_set[:target_version] = {name: 'target_version', data_type: 'STRING', value: '', label: 'b5165f68-b934-5c79-ac71-bd5375f7c809', label_display: 'mapping target code system version', removable: false, display: false, required: false}
        # @map_set[:comments] = {name: 'comments', data_type: 'STRING', value: '', label: 'Comments', label_display: 'Comments', removable: false, display: false, required: false}

        # add the definitions for the template item fields
        @map_set[:item_fields] = []
        # @map_set[:item_field_equivalence] = {name: 'qualifier', data_type: 'SELECT', value: '', label: '8e84c657-5f47-51b8-8ebf-89a9d025a9ef', label_display: 'mapping qualifier', removable: false, display: false, required: false, options: [{value: '', label: 'No Restrictions'}, {value: '8aa6421d-4966-5230-ae5f-aca96ee9c2c1', label: 'Exact'}, {value: 'c1068428-a986-5c12-9583-9b2d3a24fdc6', label: 'Broader Than'}, {value: '250d3a08-4f28-5127-8758-e8df4947f89c', label: 'Narrower Than'}]}

        @set_id = params[:set_id]

        if @set_id &&  @set_id != ''

            set = MappingApis::get_mapping_api(action: MappingApiActions::ACTION_SET, uuid_or_id: @set_id,  additional_req_params: {coordToken: coordinates_token, expand: 'comments'})

            if set.is_a? CommonRest::UnexpectedResponse
                return @map_set
            end

            vuid = IdAPIsRest.get_id(uuid_or_id: @set_id, action: IdAPIsRestActions::ACTION_TRANSLATE, additional_req_params: {outputType: 'vuid'})

            if vuid.respond_to?(:value)
                @map_set[:vuid] = vuid.value
            else
                @map_set[:vuid] = ''
            end

            extended_fields = set.mapSetExtendedFields

            extended_fields.each do |field|

                name = field.extensionNameConceptIdentifiers.uuids.first
                label = field.extensionNameConceptIdentifiers.uuids.first
                label_display = field.extensionNameConceptDescription
                value = field.extensionValue.data
                removable = true
                display = true
                data_type = field.extensionValue.class.to_s.remove('Gov::Vha::Isaac::Rest::Api1::Data::Sememe::DataTypes::RestDynamicSememe')

                # if the field is buiness rules then pull it out and handle it specially
                # TODO - use the first line when implemented in the metadata
                # if label == $isaac_metadata_auxiliary['DYNAMIC_SEMEME_COLUMN_BUSINESS_RULES']['uuids'].first[:uuid]
                if label == '7ebc6742-8586-58c3-b49d-765fb5a93f35'

                    @map_set[:rules] = value
                    next
                end

                if value == nil && value == ''
                    display = false
                end

                @map_set[:include_fields] << name
                @map_set[name] = {name: name, data_type: data_type, value: value, label: label, label_display: label_display, removable: removable, display: display, required: false}

                if field.extensionValue.class == DATA_TYPES_CLASS::RestDynamicSememeNid || field.extensionValue.class == DATA_TYPES_CLASS::RestDynamicSememeUUID

                    @map_set[name][:data_type] = 'UUID'

                    if display

                        if field.extensionValue.class == DATA_TYPES_CLASS::RestDynamicSememeNid
                            @map_set[name][:value] = IdAPIsRest.get_id(uuid_or_id: value, action: IdAPIsRestActions::ACTION_TRANSLATE, additional_req_params: {inputType: 'nid', outputType: 'uuid'}).value
                        end

                        @map_set[name.to_s + '_display'] = field.extensionValue.conceptDescription
                    end
                end

            end

            item_fields = set.mapItemFieldsDefinition

            item_fields.each do |field|

                name = field.columnLabelConcept.uuids.first
                label = name
                label_display = field.columnName
                description = field.columnDescription
                order = field.columnOrder.to_s
                data_type = field.columnDataType.enumName
                required = field.columnRequired
                validator_types = field.columnValidatorTypes
                validators = field.columnValidatorData
                removable = true
                display = true

                @map_set[:item_fields] << name
                @map_set['item_field_' + name] = {name: name, description: description, order: order, data_type: data_type, required: required, label: label, label_display: label_display, removable: removable, display: display}

                field_type = 'STRING'

                # if data_type == 'UUID'
                #
                #     field_type = 'concept'
                #
                #     validator_types.each_with_index do |validator_type, index|
                #
                #         if validators[index].class == DATA_TYPES_CLASS::RestDynamicSememeUUID && validator_type.enumName == 'IS KIND OF' && validators[index].dataObjectType.enumName == 'CONCEPT'
                #
                #             field_type = 'select'
                #
                #             option_concepts = TaxonomyRest.get_isaac_concept(uuid: validators[index].data, additional_req_params: {coordToken: coordinates_token})
                #
                #             if !option_concepts.is_a? CommonRest::UnexpectedResponse
                #
                #                 options = []
                #
                #                 option_concepts.children.each do |option_concept|
                #
                #                     options << option_concept.conChronology.description
                #                 end
                #
                #                 @map_set['item_field_' + name][:options] = options
                #             end
                #         end
                #     end
                # else
                #     field_type = 'text'
                # end

                @map_set['item_field_' + name][:type] = data_type

                session[:mapset_item_definitions] << @map_set['item_field_' + name]

            end

            @map_set[:set_id] = set.identifiers.uuids.first
            @map_set[:name] = set.name
            @map_set[:description] = set.description
            @map_set[:state] = set.mappingSetStamp.state.enumName
            @map_set[:time] = DateTime.strptime((set.mappingSetStamp.time / 1000).to_s, '%s').strftime('%m/%d/%Y')
            @map_set[:author] = get_concept_metadata(set.mappingSetStamp.authorSequence)
            @map_set[:module] = get_concept_metadata(set.mappingSetStamp.moduleSequence)
            @map_set[:path] = get_concept_metadata(set.mappingSetStamp.pathSequence)

            if set.comments.length == 0
                @map_set[:comment] = ''
                @map_set[:comment_id] = '0'
            else
                @map_set[:comment] = set.comments.first.comment
                @map_set[:comment_id] = set.comments.first.identifiers.uuids.first
            end

            @viewer_title = @map_set[:name]

            @map_items = get_overview_items_results(@map_set[:set_id])
        else

            @mapping_action = 'create_set'
            @viewer_title = 'Create New Map Set'
        end
    end

    def get_overview_items_results(set_id = nil)

        coordinates_token = session[:coordinatestoken].token
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

        items = MappingApis::get_mapping_api(action: MappingApiActions::ACTION_ITEMS, uuid_or_id: set_id,  additional_req_params: {coordToken: coordinates_token, allowedStates: view_params['statesToView'], expand: 'referencedDetails,comments '}) # CommonRest::CacheRequest => false

        if items.is_a? CommonRest::UnexpectedResponse
            return {total_number: 0, data: []}
        end

        items.each do |item|

            item_hash = {}

            item_hash[:item_id] = item.identifiers.uuids.first
            item_hash[:source_concept] = item.sourceConcept.uuids.first
            item_hash[:source_concept_display] = item.sourceDescription
            item_hash[:target_concept] = item.targetConcept

            if item_hash[:target_concept] != nil && item_hash[:target_concept] != ''
                item_hash[:target_concept] = item_hash[:target_concept].uuids.first
            end

            item_hash[:state] = item.mappingItemStamp.state.enumName

            item_hash[:qualifier_concept] = item.qualifierConcept

            if item_hash[:qualifier_concept] != nil && item_hash[:qualifier_concept] != ''
                item_hash[:qualifier_concept] = item_hash[:qualifier_concept].uuids.first
            end

            item_hash[:target_concept_display] = item.targetDescription
            item_hash[:qualifier_concept_display] = item.qualifierDescription
            item_hash[:state] = item.mappingItemStamp.state.enumName
            item_hash[:time] = DateTime.strptime((item.mappingItemStamp.time / 1000).to_s, '%s').strftime('%m/%d/%Y')
            item_hash[:author] = get_concept_metadata(item.mappingItemStamp.authorSequence)
            item_hash[:module] = get_concept_metadata(item.mappingItemStamp.moduleSequence)
            item_hash[:path] = get_concept_metadata(item.mappingItemStamp.pathSequence)

            if item.comments.length == 0
                item_hash[:comment] = ''
                item_hash[:comment_id] = '0'
            else
                item_hash[:comment] = item.comments.first.comment
                item_hash[:comment_id] = item.comments.first.identifiers.uuids.first
            end

            item.mapItemExtendedFields.each_with_index do |field, index|

                if field != nil

                    field_info = session[:mapset_item_definitions][field.columnNumber]

                    # TODO - look into GEM mappings having data type and field data that doesn't match (GEM PCS ICD-10 to ICD-9)
                    if field_info[:data_type] == 'UUID'

                        if field.respond_to? :conceptDescription
                            item_hash[field_info[:name] + '_display'] = field.conceptDescription
                        else
                            item_hash[field_info[:name] + '_display'] = field.data
                        end
                    end

                    if field_info[:data_type] == 'LONG' && field_info[:label_display].downcase.include?('date')
                        item_hash[field_info[:name]] = DateTime.strptime(field.data.to_s, '%Q').strftime('%m/%d/%Y %H:%M:%S:%L')
                    else
                        item_hash[field_info[:name]] = field.data
                    end
                end
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

        if params[:komet_mapping_set_editor_state].downcase == 'active'
            active = true
        else
            active = false
        end

        body_params = {name: set_name, description: description, active: active}
        request_params = {editToken: get_edit_token}

        if set_id && set_id != ''

            return_value =  MappingApis::get_mapping_api(uuid_or_id: set_id, action: MappingApiActions::ACTION_UPDATE_SET, additional_req_params: request_params, body_params: body_params)

            if return_value.is_a? CommonRest::UnexpectedResponse
                failed_writes[:set] << {id: :set, error: 'The set was unable to be updated.'}
            else
                successful_writes += 1
            end
        else

            set_extended_fields = []
            item_extended_fields = []

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

                # TODO - use the first line when implemented in the metadata
                #rules_id = $isaac_metadata_auxiliary['DYNAMIC_SEMEME_COLUMN_BUSINESS_RULES']['uuids'].first[:uuid]
                rules_id = '7ebc6742-8586-58c3-b49d-765fb5a93f35'

                set_extended_fields << {extensionNameConcept: rules_id, extensionValue: {'@class' => 'gov.vha.isaac.rest.api1.data.sememe.dataTypes.RestDynamicSememeString', columnNumber: 1, data: params[:komet_mapping_set_editor_rules]}}
            end

            body_params[:mapSetExtendedFields] = set_extended_fields

            if params['komet_mapping_set_editor_items_include_fields'] != nil

                params['komet_mapping_set_editor_items_include_fields'].each do |item_field|

                    item_field_label = params['komet_mapping_set_editor_items_include_fields_' + item_field + '_label']
                    item_field_data_type = params['komet_mapping_set_editor_items_include_fields_' + item_field + '_data_type']
                    item_field_required = params['komet_mapping_set_editor_items_include_fields_' + item_field + '_required']

                    item_extended_fields << {columnLabelConcept: item_field_label, columnDataType: item_field_data_type, columnRequired: item_field_required}
                end

                body_params[:mapItemExtendedFieldsDefinition] = item_extended_fields
            end

            return_value = MappingApis::get_mapping_api(action: MappingApiActions::ACTION_CREATE_SET, additional_req_params: request_params, body_params: body_params )

            if return_value.is_a? CommonRest::UnexpectedResponse

                failed_writes[:set] << {id: :set, error: 'The set was unable to be created.'}
                render json: {set_id: nil, failed_writes: failed_writes} and return
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

        if params[:items]

            params[:items].each do |item_id, item|

                target_concept = nil

                if item['target_concept'] != nil && item['target_concept'] != ''
                    target_concept = item['target_concept']
                end

                if item['state'].downcase == 'active'
                    active = true
                else
                    active = false
                end

                qualifier_concept = nil

                if item['qualifier_concept'] != nil && item['qualifier_concept'] != ''
                    qualifier_concept = item['qualifier_concept']
                end

                body_params = {targetConcept: target_concept, qualifierConcept: qualifier_concept, active: active}

                extended_fields = []

                field_info.each do |field|

                    data_type = field[:data_type]
                    data = item[field[:name]]

                    if data_type != 'UUID'

                        if ['FLOAT', 'DOUBLE'].include?(data_type)
                            data = BigDecimal.new(data);

                        elsif ['LONG', 'INTEGER'].include?(data_type)

                            if data_type == 'LONG' && field[:label_display].downcase.include?('date') && data.include?('/)')
                                data = DateTime.strptime(data, '%m/%d/%Y %H:%M:%S:%L').strftime('%Q')
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

                body_params[:mapItemExtendedFields] = extended_fields
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
                    body_params[:sourceConcept] = item['source_concept']

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
            end
        end

        # clear taxonomy caches after writing data
        if successful_writes > 0
            clear_rest_caches
        end

        render json: {set_id: set_id, failed: failed_writes}
    end

end