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

    before_filter :init_session
    skip_before_filter :set_render_menu, :only => [:map_set_editor]
    skip_after_action :verify_authorized

    DATA_TYPES_CLASS = Gov::Vha::Isaac::Rest::Api1::Data::Sememe::DataTypes

    def init_session

    end

    def load_tree_data

        coordinates_token = session[:coordinatestoken].token
        text_filter = params[:text_filter]
        set_filter = params[:set_filter]
        view_params = params[:view_params]
        mapping_tree = []

        map_sets_results = MappingApis::get_mapping_api(action: MappingApiActions::ACTION_SETS,  additional_req_params: {coordToken: coordinates_token, CommonRest::CacheRequest => false} )

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
        @previous_set_id = params[:previous_set_id]
        @view_params = params[:view_params]

        if @view_params == nil
            @view_params = {statesToView: 'both'}
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

        map_sets_results = MappingApis::get_mapping_api(action: MappingApiActions::ACTION_SETS,  additional_req_params: {coordToken: coordinates_token, CommonRest::CacheRequest => false} )

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
        @map_set = {id: '', name: '', description: '', version: '', vuid: '', rules: '', include_fields: [], state: '', status: 'Active', time: '', module: '', path: ''}
        @map_set[:include_fields] = ['source_system', 'source_version', 'target_system', 'target_version', 'equivalence', 'comments']
        @map_set[:item_fields] = []
        @map_set[:source_system] = {name: 'source_system', data_type: 'UUID', value: '', label: '32e30e80-3fac-5317-80cf-d85eab22fa9e', label_display: 'mapping source code system', removable: false, display: false, required: false}
        @map_set[:source_system_display] = ''
        @map_set[:source_version] = {name: 'source_version', data_type: 'STRING', value: '', label: '5b3479cb-25b2-5965-a031-54238588218f', label_display: 'mapping source code system version', removable: false, display: false, required: false}
        @map_set[:target_system] = {name: 'target_system', data_type: 'UUID', value: '', label: '6b31a67a-7e6d-57c0-8609-52912076fce8', label_display: 'mapping target code system', removable: false, display: false, required: false}
        @map_set[:target_system_display] = ''
        @map_set[:target_version] = {name: 'target_version', data_type: 'STRING', value: '', label: 'b5165f68-b934-5c79-ac71-bd5375f7c809', label_display: 'mapping target code system version', removable: false, display: false, required: false}
        @map_set[:equivalence] = {name: 'equivalence', data_type: 'STRING', value: '', label: '8e84c657-5f47-51b8-8ebf-89a9d025a9ef', label_display: 'mapping qualifier', removable: false, display: false, required: false, options: ['No Restrictions', 'Exact', 'Broader Than', 'Narrower Than']}
        @map_set[:comments] = {name: 'comments', data_type: 'STRING', value: '', label: 'Comments', label_display: 'Comments', removable: false, display: false, required: false}
        @set_id = params[:set_id]

        if @set_id &&  @set_id != ''

            set = MappingApis::get_mapping_api(action: MappingApiActions::ACTION_SET, uuid_or_id: @set_id,  additional_req_params: {coordToken: coordinates_token, CommonRest::CacheRequest => false})

            Gov::Vha::Isaac::Rest::Api1::Data::Sememe::RestDynamicSememeData
            if set.is_a? CommonRest::UnexpectedResponse
                return @map_set
            end

            extended_fields = set.mapSetExtendedFields

            extended_fields.each do |field|

                name = field.extensionNameConcept
                label = name
                label_display = field.extensionNameConceptDescription
                value = field.extensionValue.data
                removable = true
                display = true
                data_type = field.extensionValue.class.to_s.remove('Gov::Vha::Isaac::Rest::Api1::Data::Sememe::DataTypes::RestDynamicSememe')

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

            # add the definitions for the static item fields
            #@map_set['item_field_' + name] = {name: '1009096', description: 'Map source concept', order: order, data_type: data_type, required: true, label: 'c2af804c-bb05-3436-9f21-d37feb6a3ce4', label_display: 'Map source concept', removable: false, display: true}

            item_fields.each do |field|

                name = field.columnConceptSequence.to_s
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
            @map_set[:vuid] = '4500635'

            @viewer_title = @map_set[:description]

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

        items = MappingApis::get_mapping_api(action: MappingApiActions::ACTION_ITEMS, uuid_or_id: set_id,  additional_req_params: {coordToken: coordinates_token, expand: 'referencedDetails,comments '}) # CommonRest::CacheRequest => false

        if items.is_a? CommonRest::UnexpectedResponse
            return {total_number: 0, data: []}
        end

        items.each do |item|

            item_hash = {}

            item_hash[:item_id] = item.identifiers.uuids.first
            item_hash[:source_concept] = target_concept = IdAPIsRest.get_id(uuid_or_id: item.sourceConcept, action: IdAPIsRestActions::ACTION_TRANSLATE, additional_req_params: {inputType: 'conceptSequence', outputType: 'uuid'}).value
            item_hash[:source_concept_display] = item.sourceDescription
            item_hash[:target_concept] = item.targetConcept

            if item_hash[:target_concept] != nil || item_hash[:target_concept] != ''
                item_hash[:target_concept] = target_concept = IdAPIsRest.get_id(uuid_or_id: item_hash[:target_concept], action: IdAPIsRestActions::ACTION_TRANSLATE, additional_req_params: {inputType: 'conceptSequence', outputType: 'uuid'}).value
            end

            item_hash[:target_concept_display] = item.targetDescription
            item_hash[:comments] = ''
            item_hash[:state] = item.mappingItemStamp.state.enumName
            item_hash[:time] = DateTime.strptime((item.mappingItemStamp.time / 1000).to_s, '%s').strftime('%m/%d/%Y')
            item_hash[:author] = get_concept_metadata(item.mappingItemStamp.authorSequence)
            item_hash[:module] = get_concept_metadata(item.mappingItemStamp.moduleSequence)
            item_hash[:path] = get_concept_metadata(item.mappingItemStamp.pathSequence)

            item.mapItemExtendedFields.each_with_index do |field, index|

                if field != nil

                    field_info = session[:mapset_item_definitions][field.columnNumber]

                    if (field_info[:data_type] == 'UUID')
                        item_hash[field_info[:name] + '_display'] = field.conceptDescription
                    end

                    item_hash[field_info[:name]] = field.data
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

        # post_test = MappingApis::get_mapping_api(action: MappingApiActions::ACTION_CREATE_SET,  body_params: {name: "Map Set Test 1", description: "The first test of creating a mapset.", purpose: "The first test of creating a mapset using the rest APIs." } )
        # put_test = MappingApis::get_mapping_api(uuid_or_id: '1ebfe2e3-4a9d-4cbe-ae21-0986e89ad9f1', action: MappingApiActions::ACTION_UPDATE_SET, additional_req_params: {state: "Active"},  body_params: {name: "Map Set Test 1.1", description: "The second test of updating a mapset.", purpose: "The second test of updating a mapset using the rest APIs." } )

        set_id = params[:komet_mapping_set_editor_set_id]
        set_name = params[:komet_mapping_set_editor_name]
        description = params[:komet_mapping_set_editor_description]

        if params[:komet_mapping_set_editor_state].downcase == 'active'
            active = true
        else
            active = false
        end


        # source_system: source_system, source_system_display: source_system_display, source_version: source_version, target_system: target_system, target_system_display: target_system_display, target_version: target_version
        body_params = {name: set_name, description: description, active: active}
        request_params = {editToken: get_edit_token}

        if set_id && set_id != ''
            MappingApis::get_mapping_api(uuid_or_id: set_id, action: MappingApiActions::ACTION_UPDATE_SET, additional_req_params: request_params, body_params: body_params)
        else

            set_extended_fields = []
            item_extended_fields = []

            if params['komet_mapping_set_editor_include_fields'] != nil

                params['komet_mapping_set_editor_include_fields'].each do |set_field|

                    set_field_label = params['komet_mapping_set_editor_include_fields_' + set_field + '_label']
                    set_field_label = IdAPIsRest.get_id(uuid_or_id: set_field_label, action: IdAPIsRestActions::ACTION_TRANSLATE, additional_req_params: {inputType: 'uuid', outputType: 'conceptSequence'}).value

                    set_field_data_type = params['komet_mapping_set_editor_include_fields_' + set_field + '_data_type']

                    if set_field_data_type != 'UUID'
                        set_field_data_type = set_field_data_type.downcase
                        set_field_data_type[0] = params['komet_mapping_set_editor_include_fields_' + set_field + '_data_type'][0]
                    end

                    set_field_data_type = 'gov.vha.isaac.rest.api1.data.sememe.dataTypes.RestDynamicSememe' + set_field_data_type
                    set_field_value = params['komet_mapping_set_editor_' + set_field]

                    set_extended_fields << {extensionNameConcept: set_field_label, extensionValue: {'@class' => set_field_data_type, columnNumber: 1, data: set_field_value}}
                end

                body_params[:mapSetExtendedFields] = set_extended_fields
            end

            if params['komet_mapping_set_editor_items_include_fields'] != nil

                params['komet_mapping_set_editor_items_include_fields'].each do |item_field|

                    item_field_label = IdAPIsRest.get_id(uuid_or_id: item_field, action: IdAPIsRestActions::ACTION_TRANSLATE, additional_req_params: {inputType: 'uuid', outputType: 'conceptSequence'}).value
                    item_field_data_type = params['komet_mapping_set_editor_items_include_fields_' + item_field + '_data_type']
                    item_field_required = params['komet_mapping_set_editor_items_include_fields_' + item_field + '_required']

                    item_extended_fields << {columnLabelConcept: item_field_label, columnDataType: item_field_data_type, columnRequired: item_field_required}
                end

                body_params[:mapItemExtendedFieldsDefinition] = item_extended_fields
            end

            return_value = MappingApis::get_mapping_api(action: MappingApiActions::ACTION_CREATE_SET, additional_req_params: request_params, body_params: body_params )

            if return_value.is_a? CommonRest::UnexpectedResponse

                render json: {set_id: nil}
                return
            end

            set_id = return_value.uuid
        end

        # clear taxonomy caches after writing data
        clear_rest_caches

        render json: {set_id: set_id}
    end

    def process_map_item

        set_id = params[:set_id]
        field_info = session[:mapset_item_definitions]
        failed_writes = []

        if params[:items]

            params[:items].each do |item_id, item|

                target_concept = nil

                if item['target_concept'] != nil || item['target_concept'] != ''
                    target_concept = IdAPIsRest.get_id(uuid_or_id: item['target_concept'], action: IdAPIsRestActions::ACTION_TRANSLATE, additional_req_params: {inputType: 'uuid', outputType: 'conceptSequence'}).value
                end

                body_params = {targetConcept: target_concept, qualifierConcept: 230}

                extended_fields = []

                field_info.each do |field|

                    data_type = field[:data_type]
                    data = item[field[:name]]

                    if data_type != 'UUID'

                        if ['FLOAT', 'DOUBLE'].include?(data_type)
                            data = BigDecimal.new(data);
                        elsif ['LONG', 'INTEGER'].include?(data_type)
                            data =data.to_i;
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

                # if the item ID is a UUID, then it is an existing item to be updated, otherwise it is a new item to be created
                if is_id?(item_id)

                    return_value = MappingApis::get_mapping_api(action: MappingApiActions::ACTION_UPDATE_ITEM, uuid_or_id: item_id, additional_req_params: {editToken: get_edit_token}, body_params: body_params)

                    if return_value.is_a? CommonRest::UnexpectedResponse
                        failed_writes << {id: item_id}
                    end
                else

                    body_params[:mapSetConcept] = IdAPIsRest.get_id(uuid_or_id: set_id, action: IdAPIsRestActions::ACTION_TRANSLATE, additional_req_params: {inputType: 'uuid', outputType: 'conceptSequence'}).value
                    body_params[:sourceConcept] = IdAPIsRest.get_id(uuid_or_id: item['source_concept'], action: IdAPIsRestActions::ACTION_TRANSLATE, additional_req_params: {inputType: 'uuid', outputType: 'conceptSequence'}).value

                    return_value = MappingApis::get_mapping_api(action: MappingApiActions::ACTION_CREATE_ITEM, additional_req_params: {editToken: get_edit_token}, body_params: body_params)

                    if return_value.is_a? CommonRest::UnexpectedResponse
                        failed_writes << {id: item_id}
                    end
                end

            end
        end

        # clear taxonomy caches after writing data
        clear_rest_caches

        render json: {set_id: set_id, failed: failed_writes}
    end
end