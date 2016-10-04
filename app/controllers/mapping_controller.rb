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

##
# MappingController -
# handles the concept mapping screens
class MappingController < ApplicationController
    include ApplicationHelper, CommonController

    before_filter :init_session
    skip_before_filter :set_render_menu, :only => [:map_set_editor]

    DATA_TYPES_CLASS = Gov::Vha::Isaac::Rest::Api1::Data::Sememe::DataTypes

    def init_session

        if true #!session['map_set_data']

            session['map_tree_data'] = [{id: '1', set_id: '1', text: 'Set 1', icon: 'komet-tree-node-icon fa fa-folder', a_attr: {class: 'komet-context-menu', 'data-menu-type' => 'map_set', 'data-menu-uuid' => '1'}},
                                        {id: '2', set_id: '2', text: 'Set 2', icon: 'komet-tree-node-icon fa fa-folder', a_attr: {class: 'komet-context-menu', 'data-menu-type' => 'map_set', 'data-menu-uuid' => '2'}}]

            session['map_set_data'] = [{id: '1', name: 'Set 1', purpose: 'Test 1', description: 'Set 1 Description', version: '111', vuid: '1111', source: '1', source_display: 'Source 1', source_version: '111', target: '1', target_display: 'Target 1', target_version: '111', rules: 'Here are rules...', state: 'Pending', status: 'Active', time: '10/10/2016', module: 'Development', path: 'Path'},
                                       {id: '2', name: 'Set 2', purpose: 'Test 2', description: 'Set 2 Description', version: '222', vuid: '2222', source: '2', source_display: 'Source 2', source_version: '222', target: '2', target_display: 'Target 2', target_version: '222', rules: 'Here are rules...', state: 'Pending', status: 'Active', time: '02/02/2022', module: 'Development', path: 'Path'}]

            session['map_item_data'] = [{id: '1', set_id: '1', source: '11', source_display: 'Source 11', target: 'Target 11', target_display: 'Target 11', qualifier: 'No Qualifier', comments: 'This is a comment', review_state: 'Pending', status: 'Active', time: '10/10/2016', module: 'Development', path: 'Path'},
                                        {id: '2', set_id: '1', source: '12', source_display: 'Source 12', target: 'Target 12', target_display: 'Target 12', qualifier: 'No Qualifier', comments: 'This is a comment', review_state: 'Pending', status: 'Active', time: '10/10/2016', module: 'Development', path: 'Path'},
                                        {id: '3', set_id: '2', source: '21', source_display: 'Source 21', target: 'Target 21', target_display: 'Target 21', qualifier: 'No Qualifier', comments: 'This is a comment', review_state: 'Pending', status: 'Active', time: '10/10/2016', module: 'Development', path: 'Path'},
                                        {id: '4', set_id: '2', source: '22', source_display: 'Source 22', target: 'Target 22', target_display: 'Target 22', qualifier: 'No Qualifier', comments: 'This is a comment', review_state: 'Pending', status: 'Active', time: '10/10/2016', module: 'Development', path: 'Path'}]
        end
    end

    def load_tree_data

        coordinates_token = session[:coordinatestoken].token
        text_filter = params[:text_filter]
        set_filter = params[:set_filter]
        mapping_tree = []

        map_sets_results = MappingApis::get_mapping_api(action: MappingApiActions::ACTION_SETS,  additional_req_params: {coordToken: coordinates_token, CommonRest::CacheRequest => false} )

        map_sets_results.each do |set|

            set_hash = {}

            set_hash[:id] = get_next_id
            set_hash[:set_id] = set.identifiers.uuids.first
            set_hash[:text] = set.name
            set_hash[:state] = set.mappingSetStamp.state.name
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

        if @viewer_id == nil || @viewer_id == '' || @viewer_id == 'new'
            @viewer_id = get_next_id.to_s
        end

        if @mapping_action == 'set_details' || @mapping_action == 'create_set'
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

        map_sets_results = MappingApis::get_mapping_api(action: MappingApiActions::ACTION_SETS,  additional_req_params: {coordToken: coordinates_token, CommonRest::CacheRequest => false} )

        map_sets_results.each do |set|

            set_hash = {}

            set_hash[:set_id] = set.identifiers.uuids.first
            set_hash[:name] = set.name
            set_hash[:description] = set.description
            set_hash[:state] = set.mappingSetStamp.state.name
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
        @map_set[:source_system] = {name: 'source_system', type: 'concept', value: '', label: 'Source System', label_display: 'Source System', removable: false, display: false}
        @map_set[:source_system_display] = ''
        @map_set[:source_version] = {name: 'source_version', type: 'text', value: '', label: 'Source Version', label_display: 'Source Version', removable: false, display: false}
        @map_set[:target_system] = {name: 'target_system', type: 'concept', value: '', label: 'Target System', label_display: 'Target System', removable: false, display: false}
        @map_set[:target_system_display] = ''
        @map_set[:target_version] = {name: 'target_version', type: 'text', value: '', label: 'Target Version', label_display: 'Target Version', removable: false, display: false}
        @map_set[:equivalence] = {name: 'equivalence', type: 'select', value: '', label: 'Equivalence Type', label_display: 'Equivalence Type', removable: false, display: false, options: ['No Restrictions', 'Exact', 'Broader Than', 'Narrower Than']}
        @map_set[:comments] = {name: 'comments', type: 'textarea', value: '', label: 'Comments', label_display: 'Comments', removable: false, display: false}
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

                if value == nil && value == ''
                    display = false
                end

                if field.extensionValue.class == DATA_TYPES_CLASS::RestDynamicSememeString
                    type = 'text'

                elsif field.extensionValue.class == DATA_TYPES_CLASS::RestDynamicSememeNid || field.extensionValue.class == DATA_TYPES_CLASS::RestDynamicSememeUUID

                    type = 'concept'
                    @map_set[name + '_display'] = value

                elsif name == '-2147483446'

                    type = 'concept'
                    value = '6e60d7fd-3729-5dd3-9ce7-6d97c8f75447'
                    removable = false
                    @map_set[name + '_display'] = 'VHAT'
                end

                @map_set[:include_fields] << name
                @map_set[name] = {name: name, type: type, value: value, label: label, label_display: label_display, removable: removable, display: display}

            end

            item_fields = set.mapItemFieldsDefinition

            item_fields.each do |field|

                name = field.columnConceptSequence.to_s
                label = name
                label_display = field.columnName
                description = field.columnDescription
                order = field.columnOrder.to_s
                data_type = field.columnDataType.name
                required = field.columnRequired
                validator_types = field.columnValidatorTypes
                validators = field.columnValidatorData
                removable = true
                display = true

                @map_set[:item_fields] << name
                @map_set['item_field_' + name] = {name: name, description: description, order: order, data_type: data_type, required: required, label: label, label_display: label_display, removable: removable, display: display}

                field_type = 'text'

                # if data_type == 'UUID'
                #
                #     field_type = 'concept'
                #
                #     validator_types.each_with_index do |validator_type, index|
                #
                #         if validators[index].class == DATA_TYPES_CLASS::RestDynamicSememeUUID && validator_type.name == 'Is Kind Of' && validators[index].dataObjectType.name == 'CONCEPT'
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

                @map_set['item_field_' + name][:type] = field_type

                session[:mapset_item_definitions] << @map_set['item_field_' + name]

            end

            @map_set[:set_id] = set.identifiers.uuids.first
            @map_set[:name] = set.name
            @map_set[:description] = set.description
            @map_set[:state] = set.mappingSetStamp.state.name
            @map_set[:time] = DateTime.strptime((set.mappingSetStamp.time / 1000).to_s, '%s').strftime('%m/%d/%Y')
            @map_set[:author] = get_concept_metadata(set.mappingSetStamp.authorSequence)
            @map_set[:module] = get_concept_metadata(set.mappingSetStamp.moduleSequence)
            @map_set[:path] = get_concept_metadata(set.mappingSetStamp.pathSequence)
            @map_set[:source_system][:value] = '11'
            @map_set[:source_system_display] = 'Source System Test'
            @map_set[:source_version][:value] = 'Source Version Test'
            @map_set[:target_system][:value] = '22'
            @map_set[:target_system_display] = 'Target System Test'
            @map_set[:target_version][:value] = 'Target Version Test'
            @map_set[:equivalence][:value] = 'Exact'
            @map_set[:comments][:value] = 'Comments Test'
            @map_set[:rules] = 'Business rules test'
            @map_set[:version] = '12.4'
            @map_set[:vuid] = '4500635'

            @viewer_title = @map_set[:description]
        else

            @mapping_action = 'create_set'
            @viewer_title = 'Create New Map Set'
        end
    end

    def get_overview_items_results

        coordinates_token = session[:coordinatestoken].token
        column_definitions = {}

        session[:mapset_item_definitions].each do |definition|
            column_definitions[definition[:name]] = definition
        end

        set_id = params[:overview_set_id]
        filter = params[:overview_sets_filter]
        show_inactive = params[:show_inactive]
        page_size = 1000 #params[:overview_items_page_size]
        page_number = 1 #params[:overview_items_page_number]
        results = {column_definitions: column_definitions, page_number: page_number}
        item_data = []
        extended_columns = []

        items = MappingApis::get_mapping_api(action: MappingApiActions::ACTION_ITEMS, uuid_or_id: set_id,  additional_req_params: {coordToken: coordinates_token, expand: 'referencedDetails,comments '}) # CommonRest::CacheRequest => false

        if items.is_a? CommonRest::UnexpectedResponse
            return {total_number: 0, page_number: 1, data: []}
        end

        #{id: '1', set_id: '1', source: '11', source_display: 'Source 11', target: 'Target 11', target_display: 'Target 11', qualifier: 'No Qualifier', comments: 'This is a comment', review_state: 'Pending', status: 'Active', time: '10/10/2016', module: 'Development', path: 'Path'},

        items.each do |item|

            item_hash = {}

            item_hash[:item_id] = item.identifiers.uuids.first
            item_hash[:source_concept] = item.sourceConcept
            item_hash[:source_concept_display] = item.sourceDescription
            item_hash[:target_concept] = item.targetConcept
            item_hash[:target_concept_display] = item.targetDescription
            item_hash[:qualifier] = item.qualifierConcept
            item_hash[:qualifier_display] = item.qualifierDescription
            item_hash[:comments] = ''
            item_hash[:state] = item.mappingItemStamp.state.name
            item_hash[:time] = DateTime.strptime((item.mappingItemStamp.time / 1000).to_s, '%s').strftime('%m/%d/%Y')
            item_hash[:author] = get_concept_metadata(item.mappingItemStamp.authorSequence)
            item_hash[:module] = get_concept_metadata(item.mappingItemStamp.moduleSequence)
            item_hash[:path] = get_concept_metadata(item.mappingItemStamp.pathSequence)

            # session[:mapset_item_definitions].each do |column|
            #
            #     if column.name == '231'
            #
            #
            #     elsif column.name == '231'
            #
            #     elsif column.name == '231'
            #
            #     end
            # end

            item.mapItemExtendedFields.each do |field|

                if field != nil
                    item_hash[session[:mapset_item_definitions][field.columnNumber][:name]] = field.data
                end
            end

            item_data << item_hash
        end

        results[:total_number] = items.length

        matching_items = session['map_item_data'].select { |item|
            item[:set_id] == set_id.to_s
        }

        results[:data] = item_data
        render json: results
    end

    def process_map_set

        # post_test = MappingApis::get_mapping_api(action: MappingApiActions::ACTION_CREATE_SET,  body_params: {name: "Map Set Test 1", description: "The first test of creating a mapset.", purpose: "The first test of creating a mapset using the rest APIs." } )
        # put_test = MappingApis::get_mapping_api(uuid_or_id: '1ebfe2e3-4a9d-4cbe-ae21-0986e89ad9f1', action: MappingApiActions::ACTION_UPDATE_SET, additional_req_params: {state: "Active"},  body_params: {name: "Map Set Test 1.1", description: "The second test of updating a mapset.", purpose: "The second test of updating a mapset using the rest APIs." } )

        set_id = params[:komet_mapping_set_editor_set_id]
        set_name = params[:komet_mapping_set_editor_name]
        description = params[:komet_mapping_set_editor_description]
        state = params[:komet_mapping_set_editor_state]


        # source_system: source_system, source_system_display: source_system_display, source_version: source_version, target_system: target_system, target_system_display: target_system_display, target_version: target_version
        body_params = {name: set_name, description: description}
        request_params = {state: state}

        if set_id && set_id != ''
            MappingApis::get_mapping_api(uuid_or_id: set_id, action: MappingApiActions::ACTION_UPDATE_SET, additional_req_params: request_params, body_params: body_params)
        else

            set_id = MappingApis::get_mapping_api(action: MappingApiActions::ACTION_CREATE_SET, additional_req_params: request_params, body_params: body_params )

            if set_id.is_a? CommonRest::UnexpectedResponse

                render json: {set_id: nil}
                return
            end

            # get the uuid from the concept sequence
            set_id = IdAPIsRest.get_id(uuid_or_id: set_id.value, action: IdAPIsRestActions::ACTION_TRANSLATE, additional_req_params: {inputType: 'conceptSequence', outputType: 'uuid'}).value
        end

        # clear taxonomy caches after writing data
        clear_rest_caches

        render json: {set_id: set_id}
    end

    def map_item_editor

        set_id = params[:set_id]
        item_id = params[:item_id]
        @viewer_id = params[:viewer_id]

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

        render 'komet_dashboard/mapping/map_item_editor'
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
            #add_to_recents(:mapping_item_source_recents, source, source_display)
        end

        if target && target != ''
            #add_to_recents(:mapping_item_target_recents, target, target_display)
        end

        # clear taxonomy caches after writing data
        clear_rest_caches

        head :ok, content_type: 'text/html'
    end
end