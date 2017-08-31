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

require './lib/isaac_rest/association_rest'
require './lib/isaac_rest/concept_rest'
require './lib/isaac_rest/sememe_rest'
require './lib/isaac_rest/id_apis_rest'
require './lib/isaac_rest/vuid_rest'
require './lib/isaac_rest/system_apis_rest'
require './lib/rails_common/util/helpers'
require './app/helpers/application_helper' #build broken w/o this

include KOMETUtilities
include ERB::Util

module ConceptConcern
    include ApplicationHelper

    ##
    # descriptions - takes a uuid and returns all of the description concepts attached to it.
    # @param [String] uuid - The UUID to look up descriptions for
    # @param [Object] view_params - various parameters related to the view filters the user wants to apply - see full definition comment at top of komet_dashboard_controller file
    # @param [Boolean] clone - Are we cloning a concept, if so we will not return the terminology IDs
    # @return [object] an array of hashes that contains the attributes
    def get_attributes(uuid, view_params, clone = false)

        coordinates_token = session[:coordinates_token].token
        return_attributes = []

        attributes = ConceptRest.get_concept(action: ConceptRestActions::ACTION_VERSION, uuid: uuid, additional_req_params: {coordToken: coordinates_token, expand: 'chronology'}.merge!(view_params))

        if attributes.is_a? CommonRest::UnexpectedResponse
            return [{value: ''}, {value: ''}, {value: ''}]
        end

        @concept_text = attributes.conChronology.description
        @concept_state = attributes.conVersion.state.enumName

        # TODO - remove the hard-coding of type to 'vhat' when the type flags are implemented in the REST APIs
        @concept_terminology_types = get_uuids_from_identified_objects(attributes.terminologyTypes)

        if attributes.isConceptDefined.nil? || !boolean(attributes.isConceptDefined)
            defined = 'Primitive'
        else
            defined = 'Fully Defined'
        end

        @concept_defined = defined

        if !clone

            # get the concept SCTID information if there is one
            coding_id = IdAPIsRest.get_id(uuid_or_id: uuid, action: IdAPIsRestActions::ACTION_TRANSLATE, additional_req_params: {outputType: 'sctid', coordToken: coordinates_token}.merge!(view_params))

            if coding_id.respond_to?(:value)
                @terminology_id = {label: 'SCTID', value: coding_id.value}
            else

                # else get the concept VUID information if there is one
                coding_id = IdAPIsRest.get_id(uuid_or_id: uuid, action: IdAPIsRestActions::ACTION_TRANSLATE, additional_req_params: {outputType: 'vuid', coordToken: coordinates_token}.merge!(view_params))

                if coding_id.respond_to?(:value)
                    @terminology_id = {label: 'VUID', value: coding_id.value}
                end
            end
        end

        return_attributes << {label: 'Time', value: DateTime.strptime((attributes.conVersion.time / 1000).to_s, '%s').strftime('%m/%d/%Y')}

        author = get_concept_metadata(attributes.conVersion.authorUUID, view_params)

        if author == 'user'
            author = 'System User'
        end

        return_attributes << {label: 'Author', value: author}

        return_attributes << {label: 'Module', value: get_concept_metadata(attributes.conVersion.moduleUUID, view_params)}
        return_attributes << {label: 'Path', value: get_concept_metadata(attributes.conVersion.pathUUID, view_params)}

        return return_attributes
    end

    ##
    # get_descriptions - takes a uuid and returns all of the description concepts attached to it.
    # @param [String] uuid - The UUID to look up descriptions for
    # @param [String] terminology_types - A comma separated list of terminology type IDs for the concept
    # @param [Object] view_params - various parameters related to the view filters the user wants to apply - see full definition comment at top of komet_dashboard_controller file
    # @param [Boolean] clone - Are we cloning a concept, if so we will replace the description and other sememe IDs with placeholders
    # @return [object] a hash that contains an array of all the descriptions
    def get_descriptions(uuid, terminology_types, view_params, clone = false)

        coordinates_token = session[:coordinates_token].token
        return_descriptions = []
        errors = []
        descriptions = ConceptRest.get_concept(action: ConceptRestActions::ACTION_DESCRIPTIONS, uuid: uuid, additional_req_params: {coordToken: coordinates_token}.merge!(view_params))

        if descriptions.is_a? CommonRest::UnexpectedResponse
            return {descriptions: return_descriptions, errors: ['There was a problem retrieving the descriptions.']}
        end

        # iterate over the array of Gov::Vha::Isaac::Rest::Api1::Data::Sememe::RestSememeDescriptionVersion returned
        descriptions.each do |description|

            description_info = {text: html_escape(description.text)}

            # TODO - remove the hard-coding of type to 'vhat' when the type flags are implemented in the REST APIs
            description_info[:terminology_type] = $isaac_metadata_auxiliary['VHAT_MODULES']['uuids'].first[:uuid]

            attributes = []

            # get the description UUID information and add it to the attributes array
            description_id = description.sememeChronology.identifiers.uuids.first
            description_state = description.sememeVersion.state.enumName
            description_time = DateTime.strptime((description.sememeVersion.time / 1000).to_s, '%s').strftime('%m/%d/%Y')
            description_author = get_concept_metadata(description.sememeVersion.authorUUID, view_params)
            description_module = get_concept_metadata(description.sememeVersion.moduleUUID, view_params)
            description_path = get_concept_metadata(description.sememeVersion.pathUUID, view_params)

            if description_author == 'user'
                description_author = 'System User'
            end

            if clone
                description_info[:description_id] = get_next_id
            else
                description_info[:description_id] = description_id
            end

            attributes << {label: 'UUID', text: description_id, state: description_state, time: description_time, author: description_author, module: description_module, path: description_path}

            header_dialects = ''

            # loop thru the dialects array, and add them to the attributes array
            description.dialects.each do |dialect|

                if clone
                    dialect_instance_id = get_next_id
                else
                    dialect_instance_id = dialect.sememeChronology.identifiers.uuids.first
                end

                dialect_state = dialect.sememeVersion.state.enumName
                dialect_time = DateTime.strptime((dialect.sememeVersion.time / 1000).to_s, '%s').strftime('%m/%d/%Y')
                dialect_author = get_concept_metadata(dialect.sememeVersion.authorUUID, view_params)
                dialect_module = get_concept_metadata(dialect.sememeVersion.moduleUUID, view_params)
                dialect_path = get_concept_metadata(dialect.sememeVersion.pathUUID, view_params)
                dialect_definition_id = dialect.sememeChronology.assemblage.uuids.first
                dialect_name = find_metadata_by_id(dialect_definition_id)

                if dialect_author == 'user'
                    dialect_author = 'System User'
                end

                if header_dialects != ''
                    header_dialects += ' ,'
                end

                header_dialects += dialect_name

                # TODO switch to using only uuids once REST APIs support it
                acceptability_id = dialect.dataColumns.first.dataIdentified.uuids.first
                acceptability_text = dialect.dataColumns.first.conceptDescription

                if acceptability_text == nil
                    acceptability_text = ''
                end

                acceptability_text.slice!(' (ISAAC)')
                header_dialects += ' (' + acceptability_text + ')'

                attributes << {
                    label: 'Dialect',
                    dialect_instance_id: dialect_instance_id,
                    dialect_definition_id: dialect_definition_id,
                    text: dialect_name,
                    acceptability_id: acceptability_id,
                    acceptability_text: acceptability_text,
                    state: dialect_state,
                    time: dialect_time,
                    author: dialect_author,
                    module: dialect_module,
                    path: dialect_path
                }
            end

            description_info[:attributes] = attributes
            description_info[:header_dialects] = header_dialects

            # process descriptions types
            description_info[:description_type_id] = description.descriptionTypeConcept.uuids.first
            description_info[:description_type] = get_concept_metadata(description_info[:description_type_id], view_params)

            case description_info[:description_type]

                when 'fully specified name'
                    description_info[:description_type_short] = 'FSN'

                when 'preferred'
                    description_info[:description_type_short] = 'PRE'

                when 'synonym'
                    description_info[:description_type_short] = 'SYN'

                when 'definition description type', 'description'
                    description_info[:description_type_short] = 'DEF'

                else
                    description_info[:description_type_short] = description_info[:description_type]
            end

            description_info[:extended_description_type_id] = ''

                # check to see if there is an extended description type
            if description.descriptionExtendedTypeConcept

                description_info[:extended_description_type_id] = description.descriptionExtendedTypeConcept.uuids.first

                # get the extended types based on the terminologies that the concept belongs to
                # description_info[:extended_description_type_options] = []
                # terminology_types_array = terminology_types.split(/\s*,\s*/)
                #
                # # loop thru the terminology types, get the module name from the metadata, and then add the type options from the session to our options variable
                # terminology_types_array.each { |terminology_type|
                #
                #     module_name = find_metadata_by_id(terminology_type)
                #     extended_type_options = session['komet_extended_description_types'][module_name.to_sym]
                #
                #     # if there are options for this terminology type add the to the column's options variable
                #     if extended_type_options != nil
                #         description_info[:extended_description_type_options].concat(extended_type_options)
                #     end
                # }
            else

                # if there is no extended description type then just use the default options
                # description_info[:extended_description_type_options] = session['komet_extended_description_types'][:default]
            end

            # process languages
            description_info[:language_id] = description.languageConcept.uuids.first
            description_info[:language] = get_concept_metadata(description_info[:language_id], view_params)

            case description_info[:language]

                when 'English language'
                    description_info[:language_short] = 'EN'

                else
                    description_info[:language_short] = description_info[:language]
            end

            # process case
            description_info[:case_significance_id] = description.caseSignificanceConcept.uuids.first
            description_info[:case_significance] = get_concept_metadata(description_info[:case_significance_id], view_params)

            case description_info[:case_significance]

                when 'description initial character sensitive'
                    description_info[:case_significance_short] = 'true'

                when 'description case sensitive'
                    description_info[:case_significance_short] = 'true'

                when 'description not case sensitive'
                    description_info[:case_significance_short] = 'false'

                else
                    description_info[:case_significance_short] = 'false'
            end

            # process nested properties
            if description.nestedSememes.length > 0

                nested_properties = process_attached_sememes(view_params, description.nestedSememes, [], {}, 1, clone, @concept_terminology_types, uuid)
                description_info[:nested_properties] = {field_info: nested_properties[:used_column_hash], data: nested_properties[:data_rows]}
                errors.concat(nested_properties[:errors])
            end

            return_descriptions << description_info
        end

        return {descriptions: return_descriptions, errors: errors}
    end

    ##
    # get_associations - takes a uuid and returns all associations related to it.
    # @param [String] uuid - The UUID to look up associations for
    # @param [Object] view_params - various parameters related to the view filters the user wants to apply - see full definition comment at top of komet_dashboard_controller file
    # @param [Boolean] clone - Are we cloning a concept, if so we will replace the association IDs with placeholders
    # @return [object] a hash that contains an array of all the associations
    def get_associations(uuid, view_params, clone = false)

        coordinates_token = session[:coordinates_token].token
        return_associations = []
        additional_req_params = {coordToken: coordinates_token, expand: 'source, target'}
        additional_req_params.merge!(view_params)

        associations = AssociationRest.get_association(action: AssociationRestActions::ACTION_WITH_SOURCE, uuid_or_id: uuid, additional_req_params: additional_req_params)

        if associations.is_a? CommonRest::UnexpectedResponse
            return return_associations
        end

        # iterate over the array of RestAssociationItemVersion returned
        associations.each do |association|

            if clone
                id = get_next_id
            else
                id = association.identifiers.uuids.first
            end

            type_id = association.associationType.uuids.first
            type = AssociationRest.get_association(action: AssociationRestActions::ACTION_TYPE, uuid_or_id: type_id, additional_req_params: {coordToken: coordinates_token}.merge!(view_params))

            if type.is_a? CommonRest::UnexpectedResponse
                return return_associations
            end

            type_text = type.description

            target_id = ''
            target_text = ''

            if association.targetConcept

                target_id = association.targetConcept.identifiers.uuids.first
                target_text = association.targetConcept.description
            end

            # TODO - remove the hard-coding of type to 'vhat' when the type flags are implemented in the REST APIs
            target_taxonomy_types = $isaac_metadata_auxiliary['VHAT_MODULES']['uuids'].first[:uuid]
            state = association.associationItemStamp.state.enumName
            time = DateTime.strptime((association.associationItemStamp.time / 1000).to_s, '%s').strftime('%m/%d/%Y')
            author = get_concept_metadata(association.associationItemStamp.authorUUID, view_params)
            association_module = get_concept_metadata(association.associationItemStamp.moduleUUID, view_params)
            path = get_concept_metadata(association.associationItemStamp.pathUUID, view_params)

            return_associations << {id: id, type_id: type_id, type_text: type_text, target_id: target_id, target_text: target_text, target_taxonomy_type: target_taxonomy_types, state: state, time: time, author: author, module: association_module, path: path}
        end

        return return_associations
    end

    ##
    # get_association_types - returns all of the association types.
    # @param [Object] view_params - various parameters related to the view filters the user wants to apply - see full definition comment at top of komet_dashboard_controller file
    # @return [object] a hash that contains an array of all the association types
    def get_association_types(view_params = {})

        coordinates_token = session[:coordinates_token].token
        return_types = []
        additional_req_params = {coordToken: coordinates_token}
        additional_req_params.merge!(view_params)

        types = AssociationRest.get_association(action: AssociationRestActions::ACTION_TYPES, additional_req_params: additional_req_params)

        if types.is_a? CommonRest::UnexpectedResponse
            return return_types
        end

        # iterate over the array of restAssociationTypeVersion returned
        types.each do |type|
            return_types << {concept_id: type.identifiers.uuids.first, concept_sequence: type.identifiers.sequence, text: type.description}
        end

        return return_types
    end

    ##
    # get_attached_sememes - takes a uuid and returns all of the non-description sememes attached to it.
    # @param [String] uuid - The UUID to look up attached sememes for
    # @param [Object] view_params - various parameters related to the view filters the user wants to apply - see full definition comment at top of komet_dashboard_controller file
    # @param [Boolean] clone - Are we cloning a concept, if so we will replace the sememe IDs with placeholders
    # @return [object] a hash that contains an array of all the columns to be displayed and an array of all the sememes
    def get_attached_sememes(uuid, view_params, clone = false)

        coordinates_token = session[:coordinates_token].token

        sememes = SememeRest.get_sememe(action: SememeRestActions::ACTION_BY_REFERENCED_COMPONENT, uuid_or_id: uuid, additional_req_params: {coordToken: coordinates_token, expand: 'chronology,nestedSememes'}.merge!(view_params))

        display_data = process_attached_sememes(view_params, sememes, [], {}, 1, clone, @concept_terminology_types, uuid)

        return {columns: display_data[:used_column_list], rows: display_data[:data_rows], field_info: display_data[:used_column_hash]}

    end

    ##
    # get_refsets - takes a uuid and returns all of the refset attached to it.
    # @param [String] uuid - The UUID to look up attached sememes for
    # @param [Object] view_params - various parameters related to the view filters the user wants to apply - see full definition comment at top of komet_dashboard_controller file
    # @return [object] a hash that contains an array of all the columns to be displayed and an array of all the refsets
    def get_refsets(uuid, view_params)

        coordinates_token = session[:coordinates_token].token
        refsets_results = {}
        sememe_types = {}
        page_number = params[:taxonomy_refsets_page_number]
        page_size = 25

        if params[:taxonomy_refsets_page_size] != nil
            page_size = params[:taxonomy_refsets_page_size]
        end

        additional_req_params = {coordToken: coordinates_token, expand: 'chronology,nestedSememes,referencedDetails', pageNum: page_number}
        additional_req_params[:maxPageSize] =  page_size
        additional_req_params.merge!(view_params)

        results = SememeRest.get_sememe(action: SememeRestActions::ACTION_BY_ASSEMBLAGE, uuid_or_id: uuid, additional_req_params:additional_req_params )

        refsets_results[:total_number] = results.paginationData.approximateTotal
        refsets_results[:page_number] = results.paginationData.pageNum
        used_column_list = []

        display_data = process_attached_refsets(view_params, results.results, sememe_types, [], used_column_list)

        refsets_results[:data] = display_data
        refsets_results[:columns] = used_column_list
        return refsets_results
    end

    private

    ##
    # get_sememe_details - takes a uuid and returns all of the description concepts attached to it.
    # @param [String] uuid - The UUID to look up descriptions for
    # @param [Object] view_params - various parameters related to the view filters the user wants to apply - see full definition comment at top of komet_dashboard_controller file
    # @return [object] a RestSememeVersion object
    def get_sememe_version_details(uuid, view_params)

        coordinates_token = session[:coordinates_token].token
        sememe = SememeRest.get_sememe(action: SememeRestActions::ACTION_VERSION, uuid_or_id: uuid, additional_req_params: {coordToken: coordinates_token, expand: 'chronology,nestedSememes'}.merge!(view_params))

        if sememe.is_a? CommonRest::UnexpectedResponse
            return nil
        end

        return sememe
    end

    ##
    # get_sememe_definition_details - takes a sememe uuid and returns all of the description concepts attached to it.
    # @param [String] uuid - The UUID to look up descriptions for
    # @param [Object] view_params - various parameters related to the view filters the user wants to apply - see full definition comment at top of komet_dashboard_controller file
    # @param [String] terminology_types - A comma seperated string of terminology type IDs. Optional, defaults to the instance variable @concept_terminology_types
    # @return [object] a RestSememeVersion object
    def get_sememe_definition_details(uuid, view_params = {}, generated_vuid = nil, terminology_types = nil, concept_id = nil)

        coordinates_token = session[:coordinates_token].token
        additional_req_params = {coordToken: coordinates_token}
        additional_req_params.merge!(view_params)
        sememe_details = {data: {}, field_info: {}, errors: []}

        # do a sememe_sememeDefinition call to get the columns that sememe has.

        sememe_definition = SememeRest.get_sememe(action: SememeRestActions::ACTION_SEMEME_DEFINITION, uuid_or_id: uuid, additional_req_params: additional_req_params)

        # if there was an error then return that information
        if sememe_definition.is_a? CommonRest::UnexpectedResponse

            sememe_details[:errors] << 'There was an error trying to create the property for UUID ' + uuid + ': ' + sememe_definition.rest_exception.conciseMessage
            return sememe_details
        end

        # process dynamic sememe definition types
        if sememe_definition.class == Gov::Vha::Isaac::Rest::Api1::Data::Sememe::RestDynamicSememeDefinition

            # TODO switch to using only uuids once REST APIs support it, and then no need for description call below
            assemblage_id = sememe_definition.assemblageConceptId.uuids.first
            sememe_name = sememe_definition.assemblageConceptDescription

            # start loading the row of sememe data with everything besides the columns
            sememe_details[:data] = {sememe_name: sememe_name, sememe_description: sememe_definition.sememeUsageDescription, sememe_instance_id: get_next_id, sememe_definition_id: assemblage_id, state: 'Active', level: 1, has_nested: false, columns: {}}

            # loop through all of the sememe's columns
            sememe_definition.columnInfo.each{ |row_column|

                column_id = row_column.columnLabelConcept.uuids.first

                # If not added to our hash of columns then add it
                if row_column && ! sememe_details[:field_info][column_id]

                    # get the column data type from the validator data if it exists, otherwise use string
                    if row_column.columnDataType.classType
                        data_type_class = row_column.columnDataType.classType
                    else
                        data_type_class = 'gov.vha.isaac.rest.api1.data.sememe.dataTypes.RestDynamicSememeString'
                    end

                    sememe_details[:field_info][column_id] = {
                        column_id: column_id,
                        name: row_column.columnName,
                        description: row_column.columnDescription,
                        data_type: row_column.columnDataType.enumName,
                        data_type_class: data_type_class,
                        column_number: row_column.columnOrder,
                        required: row_column.columnRequired,
                        column_used: false
                    }

                    if assemblage_id == $isaac_metadata_auxiliary['EXTENDED_DESCRIPTION_TYPE']['uuids'].first[:uuid]

                        # get the extended types based on the terminologies that the concept belongs to
                        sememe_details[:field_info][column_id][:dropdown_options] = []
                        terminology_types_array = terminology_types.split(/\s*,\s*/)

                        options_found = false

                        # loop thru the terminology types, get the module name from the metadata, and then add the type options from the session to our options variable
                        terminology_types_array.each { |terminology_type|

                            module_name = find_metadata_by_id(terminology_type)
                            extended_type_options = session['komet_extended_description_types'][module_name.to_sym]

                            # if there are options for this terminology type add the to the column's options variable and set the found flag
                            if extended_type_options != nil

                                sememe_details[:field_info][column_id][:dropdown_options].concat(extended_type_options)
                                options_found = true
                            end
                        }

                        # only proceed if dropdown options were found, otherwise we should leave the field along so the user can hopefully enter a string
                        if options_found

                            # add a modifier to the column ID so that our custom column properties we are adding here don't cross over to other fields with the same label
                            sememe_details[:field_info][column_id + '_EXTENDED'] = sememe_details[:field_info].delete(column_id)
                            column_id += '_EXTENDED'
                            sememe_details[:field_info][column_id][:column_id] += '_EXTENDED'
                            sememe_details[:field_info][column_id][:column_display] = 'dropdown'
                        else
                            sememe_details[:field_info][column_id][:column_display] = 'text'
                        end

                    else
                        sememe_details[:field_info][column_id][:column_display] = 'text'
                    end

                    # if we are auto generating VHAT IDs and this is one of them then generate the IDs, otherwise there is no data
                    if generated_vuid != false && user_session(UserSession::USER_PREFERENCES)[:generate_vuid] == 'true' && session[:komet_vhat_ids].include?(assemblage_id)

                        if generated_vuid == nil

                            generated_vuid = request_vuids(1, 'Terminology Editor Request')

                            # if the return has a property named startInclusive then everything was fine. If not an error occurred and should be passed along in the results
                            if generated_vuid.respond_to?('startInclusive')
                                generated_vuid = generated_vuid.startInclusive
                            else

                                sememe_details[:data][:error] = generated_vuid[:error]
                                sememe_details[:errors] << generated_vuid[:error]
                                generated_vuid = ''
                            end
                        end

                        sememe_details[:data][:columns][column_id] = {data: generated_vuid, display: ''}
                    else
                        sememe_details[:data][:columns][column_id] = {}
                    end

                end
            }
        end

        return sememe_details
    end

    ##
    # process_attached_sememes - recursively loops through an array of sememes and processes them for display.
    # @param [Object] view_params - various parameters related to the view filters the user wants to apply - see full definition comment at top of komet_dashboard_controller file
    # @param [RestSememeVersion] sememes - a hash with an array of sememes to process
    # @param [Array] used_column_list - an array of data columns for display (for easier sequential access)
    # @param [Hash] used_column_hash - a hash of data columns for display (for easier random access)
    # @param [Number] level - the level of recursion we are at.
    # @param [Boolean] clone - Are we cloning a concept, if so we will replace the sememe IDs with placeholders. Optional, defaults to false
    # @param [String] terminology_types - A comma seperated string of terminology type IDs. Optional, defaults to the instance variable @concept_terminology_types
    # @return [object] a hash that contains an array of all the columns to be displayed and an array of all the data
    def process_attached_sememes(view_params, sememes, used_column_list, used_column_hash, level, clone = false, terminology_types = @concept_terminology_types, concept_id = nil)

        additional_req_params = {coordToken: session[:coordinates_token].token}
        additional_req_params.merge!(view_params)
        data_rows = []
        refset_rows = []
        generated_vuid = nil
        errors = []

        # iterate over the array of sememes returned
        sememes.each do |sememe|

            # process dynamic sememe version types
            if sememe.class == Gov::Vha::Isaac::Rest::Api1::Data::Sememe::RestDynamicSememeVersion

                assemblage_id = sememe.sememeChronology.assemblage.uuids.first
                sememe_instance_id = sememe.sememeChronology.identifiers.uuids.first

                # use the assemblage to do a sememe_sememeDefinition call to get the columns that sememe has.
                sememe_definition = SememeRest.get_sememe(action: SememeRestActions::ACTION_SEMEME_DEFINITION, uuid_or_id: assemblage_id, additional_req_params: additional_req_params)

                # if there was an error then return that information
                if sememe_definition.is_a? CommonRest::UnexpectedResponse

                    errors << 'There was an error trying to create the property for UUID ' + assemblage_id
                    next
                end

                # if we are cloning a concept then put in a placeholder for the instance ID
                if clone
                    sememe_instance_id = get_next_id
                end

                has_nested = false

                if sememe.nestedSememes != nil && sememe.nestedSememes.length > 0
                    has_nested = true
                end

                state = sememe.sememeVersion.state.enumName
                time = DateTime.strptime((sememe.sememeVersion.time / 1000).to_s, '%s').strftime('%m/%d/%Y')
                author = get_concept_metadata(sememe.sememeVersion.authorUUID, view_params)
                sememe_module = get_concept_metadata(sememe.sememeVersion.moduleUUID, view_params)
                path = get_concept_metadata(sememe.sememeVersion.pathUUID, view_params)

                # start loading the row of sememe data with everything besides the data columns
                data_row = {
                    sememe_name: sememe_definition.assemblageConceptDescription,
                    sememe_description: sememe_definition.sememeUsageDescription,
                    sememe_instance_id: sememe_instance_id,
                    sememe_definition_id: assemblage_id,
                    state: state,
                    time: time,
                    author: author,
                    module: sememe_module,
                    path: path,
                    level: level,
                    has_nested: has_nested,
                    columns: {}
                }

                # loop through all of the sememe's data columns
                sememe_definition.columnInfo.each{ |row_column|

                    column_id = row_column.columnLabelConcept.uuids.first

                    # search to see if we have already added this column to our list of used columns.
                    list_index = used_column_list.find_index {|list_column|
                        list_column[:column_id] == column_id
                    }

                    # If not added to our list of used columns add it to the end of the list
                    if row_column && !list_index

                        # get the column data type column data if it exists, otherwise use string
                        if row_column.columnDataType.classType
                            data_type_class = row_column.columnDataType.classType
                        else
                            data_type_class = 'gov.vha.isaac.rest.api1.data.sememe.dataTypes.RestDynamicSememeString'
                        end

                        used_column_data = {
                            column_id: column_id,
                            name: row_column.columnName,
                            description: row_column.columnDescription,
                            data_type: row_column.columnDataType.enumName,
                            data_type_class: data_type_class,
                            column_number: row_column.columnOrder,
                            required: row_column.columnRequired,
                            column_used: false
                        }

                        # if this is an extended description type field then do some custom processing to provide a dropdown field. TODO - eventually this should be handled based on the field data
                        if assemblage_id == $isaac_metadata_auxiliary['EXTENDED_DESCRIPTION_TYPE']['uuids'].first[:uuid]

                            # get the extended types based on the terminologies that the concept belongs to
                            used_column_data[:dropdown_options] = []
                            terminology_types_array = terminology_types.split(/\s*,\s*/)

                            options_found = false

                            # loop thru the terminology types, get the module name from the metadata, and then add the type options from the session to our options variable
                            terminology_types_array.each { |terminology_type|

                                module_name = find_metadata_by_id(terminology_type)
                                extended_type_options = session['komet_extended_description_types'][module_name.to_sym]

                                # if there are options for this terminology type add the to the column's options variable and set the found flag
                                if extended_type_options != nil

                                    used_column_data[:dropdown_options].concat(extended_type_options)
                                    options_found = true
                                end
                            }

                            # only proceed if dropdown options were found, otherwise we should leave the field along so the user can hopefully enter a string
                            if options_found

                                # add a modifier to the column ID so that our custom column properties we are adding here don't cross over to other fields with the same label
                                column_id += '_EXTENDED'
                                used_column_data[:column_id] += '_EXTENDED'
                                used_column_data[:column_display] = 'dropdown'
                            else
                                used_column_data[:column_display] = 'text'
                            end

                       # elsif used_column_data[:data_type] == 'UUID'

                        else
                            used_column_data[:column_display] = 'text'
                        end

                        used_column_list << used_column_data
                        used_column_hash[column_id] = used_column_data
                        list_index = (used_column_list.length) - 1
                    end

                    data_column = sememe.dataColumns[row_column.columnOrder] unless !sememe.respond_to?(:dataColumns)
                    column_data = {}
                    taxonomy_ids = []

                    # if the column data is not empty, or if we are cloning it is not a taxonomy ID, process the data
                    if data_column != nil && (!clone || (clone && (!session[:komet_taxonomy_ids].include?(assemblage_id))))

                        # mark in our column lists that this column has data in at least one row
                        used_column_list[list_index][:column_used] = true
                        used_column_hash[column_id][:column_used] = true

                        data = data_column.data
                        converted_value = ''

                        # if the column is one of a specific set, make sure it has string data and see if it contains IDs. If it does look up their description
                        if ((['column name', 'target'].include?(row_column.columnName) || used_column_hash[column_id][:data_type] == 'UUID') && (data_column.data.kind_of? String) && find_ids(data_column.data)) || (data_column.respond_to?('dataIdentified') && data_column.dataIdentified.type.enumName == 'CONCEPT')

                            # the description should be included, but if not look it up
                            if data_column.respond_to?('conceptDescription')
                                converted_value = data_column.conceptDescription
                            else
                                converted_value = ConceptRest.get_concept(action: ConceptRestActions::ACTION_DESCRIPTIONS, uuid: data_column.data, additional_req_params: additional_req_params).first.text
                            end

                            # if the row is an array get the text values into a more readable form
                        elsif data_column.data.kind_of? Array

                            # loop through each item in the array and generate a comma separated list of values
                            data_column.data.each_with_index { |item, index|

                                separator = ', '

                                if index == 0
                                    data = ''
                                    separator = ''
                                end

                                data += separator + item.data.to_s
                            }

                        end

                        # store the data for the column
                        column_data = {data: html_escape(data), display: converted_value}

                    # else if we are cloning and it is a VHAT ID on a VHAT concept and not also a metadata concept, and we are auto generating VHAT IDs then get a new ID for the column
                    elsif clone && user_session(UserSession::USER_PREFERENCES)[:generate_vuid] == 'true' && terminology_types.include?($isaac_metadata_auxiliary['VHAT_MODULES']['uuids'].first[:uuid]) && !terminology_types.include?($isaac_metadata_auxiliary['ISAAC_MODULE']['uuids'].first[:uuid]) && session[:komet_vhat_ids].include?(assemblage_id)

                        # if a vuid hasn't already been generated then generate one
                        if generated_vuid == nil

                            generated_vuid = request_vuids(1, 'Terminology Editor Request')

                            # if the return has a property named startInclusive then everything was fine. If not an error occurred and should be passed along in the results
                            if generated_vuid.respond_to?('startInclusive')
                                generated_vuid = generated_vuid.startInclusive
                            else

                                data_row[:error] = generated_vuid[:error]
                                generated_vuid = ''
                            end
                        end

                        column_data = {data: generated_vuid, display: ''}
                    end

                    # add the sememe column id and data to the sememe data row
                    data_row[:columns][column_id] = column_data
                }

            end

            # if the sememe has nested sememes call this function again passing in those nested sememes and incrementing the level
            if has_nested

                sememes = sememe.nestedSememes
                nested_sememe_data = process_attached_sememes(view_params, sememes, used_column_list, used_column_hash, level + 1, clone, terminology_types, concept_id)

                data_row[:nested_rows] = nested_sememe_data[:data_rows]

            end

            # add the sememe data row to the array of return rows if it isn't a refset (no columns), else mark it as a refset and store it for adding later
            if sememe_definition.columnInfo.length > 0
                data_rows << data_row
            else

                data_row[:refset] = true
                refset_rows << data_row
            end
        end

        # add any refsets to the array of return rows
        data_rows.concat(refset_rows)

        return {data_rows: data_rows, used_column_list: used_column_list, used_column_hash: used_column_hash, errors: errors}

    end

    ##
    # process_attached_refsets - recursively loops through an array of sememes and processes them for display.
    # @param [RestSememeVersion] sememes - a hash with an array of sememes to process, a cached hash of all unique sememe data, an array of data rows for display, and an array of columns to display
    # @param [Object] view_params - various parameters related to the view filters the user wants to apply - see full definition comment at top of komet_dashboard_controller file
    # @return [object] a hash that contains an array of all the columns to be displayed and an array of all the refsets
    def process_attached_refsets(view_params, sememes, sememe_types, data_rows, used_column_list)

        additional_req_params = {coordToken: session[:coordinates_token].token}
        additional_req_params.merge!(view_params)

        #Defining first 2 columns of grid.
        used_column_list << {id:'state', field: 'state', headerName: 'status', data_type: 'string'}
        used_column_list << {id:'referencedComponentNidDescription', field: 'referencedComponentNidDescription', headerName: 'Component', data_type: 'string'}
        # iterate over the array of sememes returned
        sememes.each do |sememe|

            # process dynamic sememe version types
            if sememe.class == Gov::Vha::Isaac::Rest::Api1::Data::Sememe::RestDynamicSememeVersion

                assemblage_sequence = sememe.sememeChronology.assemblage.sequence
                uuid = sememe.sememeChronology.identifiers.uuids.first

                # use the assemblage sequence to do a concept_description call to get sememe name, then a sememe_sememeDefinition call to get the columns that sememe has.
                sememe_types[assemblage_sequence] = {sememe_name: ConceptRest.get_concept(action: ConceptRestActions::ACTION_DESCRIPTIONS, uuid: assemblage_sequence, additional_req_params: additional_req_params).first.text}
                sememe_definition = SememeRest.get_sememe(action: SememeRestActions::ACTION_SEMEME_DEFINITION, uuid_or_id: assemblage_sequence, additional_req_params: additional_req_params)

                sememe_types[assemblage_sequence][:sememe_description] = sememe_definition.sememeUsageDescription
                sememe_types[assemblage_sequence][:columns] = sememe_definition.columnInfo

                # start loading the row of sememe data with everything besides the data columns
                data_row = {sememe_name: sememe_types[assemblage_sequence][:sememe_name], sememe_description: sememe_types[assemblage_sequence][:sememe_description], uuid: uuid, id: assemblage_sequence, state: {data:sememe.sememeVersion.state.enumName,display:''},referencedComponentNidDescription: {data:sememe.sememeChronology.referencedComponentNidDescription,display:''} ,columns: {}}

                # loop through all of the sememe's data columns
                sememe_definition.columnInfo.each{|row_column|

                    column_id = row_column.columnLabelConcept.sequence

                    # search to see if we have already added this column to our list of used columns.
                    list_index = used_column_list.find_index {|list_column|
                        list_column[:id] == column_id
                    }

                    # If not added to our list of used columns add it to the end of the list
                    if row_column && !list_index

                        used_column_list << {id: column_id, field: row_column.columnName, headerName: row_column.columnName, data_type: row_column.columnDataType.enumName}
                        list_index = (used_column_list.length) - 1
                    end

                    data_column = sememe.dataColumns[row_column.columnOrder]
                    column_data = {}

                    # if the column data is not empty process the data
                    if data_column != nil

                        # mark in our column lists that this column has data in at least one row
                        used_column_list[list_index][:column_used] = true

                        data = data_column.data
                        converted_value = ''

                        # if the column is one of a specific set, make sure it has string data and see if it contains IDs. If it does look up their description
                        if (['column name', 'target'].include?(row_column.columnName)) && (data.kind_of? String) && find_ids(data)
                            converted_value = ConceptRest.get_concept(action: ConceptRestActions::ACTION_DESCRIPTIONS, uuid: data, additional_req_params: additional_req_params).first.text

                            # if the row is an array get the text values into a more readable form
                        elsif data.kind_of? Array

                            # loop through each item in the array and generate a comma separated list of values
                            data.each_with_index { |item, index|

                                separator = ', '

                                if index == 0
                                    data = ''
                                    separator = ''
                                end

                                data += separator + item.data.to_s
                            }
                        end

                        # store the data for the column
                        column_data = {data: html_escape(data), display: converted_value}
                    end

                    # add the sememe column id and data to the sememe data row
                    data_row[row_column.columnName]= column_data
                }
            end

            # add the sememe data row to the array of return rows
            data_rows << data_row

        end

        return  data_rows

    end

    ##
    # get_direct_children - takes a uuid and returns all of its direct children.
    # @param [String] type - The type of concept call to make. Options are 'concept', 'extended description', 'module'. Defaults to 'concept'
    # @param [String] concept_id - The UUID to look up children for. Defaults to nil
    # @param [Boolean] format_results - Should the results be processed. Defaults to false
    # @param [Boolean] remove_semantic_tag - Should semantic tags be removed (Just 'ISAAC' at the moment). Defaults to false
    # @param [Boolean] include_definition - should definition descriptions be looked up and included in the results. Defaults to false
    # @param [Boolean] include_nested - should nested children be included in the results. Defaults to false
    # @param [Object] view_params - various parameters related to the view filters the user wants to apply - see full definition comment at top of komet_dashboard_controller file. Defaults to an empty object
    # @param [Number] level - the level of nested concepts that is currently being processing. Defaults to 0
    # @param [String] qualifier - a string to be included after the text of each entry to serve as a identifier. Defaults to an empty string
    # @return [object] an array of children
    def get_direct_children(type: 'concept', concept_id: nil, format_results: true, remove_semantic_tag: true, include_definition: false, include_nested: true, view_params: {}, level: 0, qualifier: '')

        # set the request params for the API call
        additional_req_params = {coordToken: session[:coordinates_token].token}

        if type == 'concept' || type == 'module'

            # set the request params for the taxonomy call - getting one level of children along with a count of how many children each of them has
            additional_req_params.merge!({childDepth: 1, countChildren: true})
            additional_req_params.merge!(view_params)

            # get the children of the passed in concept
            children = TaxonomyRest.get_isaac_concept(uuid: concept_id, additional_req_params: additional_req_params)

        elsif type == 'extended description'

            additional_req_params.merge!(view_params)

            # make a call to get the descriptions for this concept
            children = SystemApis.get_system_api(action: SystemApiActions::ACTION_EXTENDED_DESCRIPTION_TYPES, uuid_or_id: concept_id, additional_req_params: additional_req_params)
        else

            # make a call to get the descriptions for this concept
            children = SystemApis.get_system_api(action: SystemApiActions::ACTION_MODULES, additional_req_params: additional_req_params)
        end

        # if there was an error return a blank array
        if children.is_a? CommonRest::UnexpectedResponse
            return []
        end

        # if this is not an extended description call get the children of the first result
        if type != 'extended description'
            children = children.children.results
        end

        # set the request params for the call to get definitions
        additional_req_params = {coordToken: session[:coordinates_token].token, includeAttributes: false}
        additional_req_params.merge!(view_params)

        # if we are processing the child list
        if format_results

            child_array = []

            # loop through all of the children
            children.each do |child|

                # if this is not an extended description call we want access into the conChronology
                if child.respond_to?('conChronology')
                    child_info = child.conChronology
                else
                    child_info = child
                end

                # get the concept description
                text = child_info.description
                definition = ''

                # TODO - replace with regex that handles any semantic tag: start with /\s\(([^)]+)\)/ (regex101.com)
                # if desired remove certain semantic tags from the concept description
                if remove_semantic_tag && text
                    text.slice!(' (ISAAC)')
                    text.slice!(' (core metadata concept)')
                end

                # if we are including the definition
                if include_definition

                    # make a call to get the descriptions for this concept
                    descriptions = ConceptRest.get_concept(action: ConceptRestActions::ACTION_DESCRIPTIONS, uuid: child_info.identifiers.uuids.first, additional_req_params: additional_req_params)

                    # as long as we didn't get an error process the results
                    unless descriptions.is_a? CommonRest::UnexpectedResponse

                        # loop through each description
                        descriptions.each do |description|

                            # if the description is a definition copy the description text and end the loop
                            if description.descriptionTypeConcept.uuids.first == $isaac_metadata_auxiliary['DEFINITION_DESCRIPTION_TYPE']['uuids'].first[:uuid]

                                definition = description.text
                                break
                            end
                        end
                    end
                end

                # add the concept information to the end of the child array, unless this is a module call then the concept should have a child or this not be the first level for it to be added to the array
                if type != 'module' || (type == 'module' && (child.childCount > 0 || level > 0))
                    child_array << {concept_id: child_info.identifiers.uuids.first, concept_sequence: child_info.identifiers.sequence, text: text, qualifier: qualifier, definition: definition, level: level}
                end

                # if we are grabbing nested children and this concept has children recursively call this function passing in the ID of this concept
                if include_nested && child.respond_to?('childCount') && child.childCount > 0

                    child_array.concat(get_direct_children(type: type, concept_id: child_info.identifiers.uuids.first, format_results: format_results, remove_semantic_tag: remove_semantic_tag, include_definition: include_definition, include_nested: include_nested, view_params: view_params, level: level + 1, qualifier: qualifier))
                end
            end

            children = child_array
        end

        return children

    end

    ##
    # generate_vhat_ids - auto generate VHAT ID properties
    # @return [object] a hash that contains an array of all the columns to be displayed and an array of all the sememes, and a string containing the generated vuid
    def generate_vhat_properties(generate_ids = true, request_reason = nil)

        vhat_properties = {field_info: {}, data: [], errors: []}
        vuid_error = nil

        # generate a vuid to use
        if generate_ids

            generated_vuid = request_vuids

            # if the return has a property named startInclusive then everything was fine. If not an error occurred and should be passed along in the results
            if generated_vuid.respond_to?('startInclusive')
                generated_vuid = generated_vuid.startInclusive
            else

                vuid_error = generated_vuid[:error]
                vhat_properties[:errors] << vuid_error
                generated_vuid = ''
            end
        else
            generated_vuid = false
        end

        vhat_properties[:generated_vuid] = generated_vuid

        session[:komet_vhat_ids].each { |id|

            new_property = get_sememe_definition_details(id, session[:edit_view_params], generated_vuid)
            vhat_properties[:field_info].merge!(new_property[:field_info])

            # if there was an error generating the vuid include it with the data row
            if vuid_error != nil
                new_property[:data][:error] = vuid_error
            end

            vhat_properties[:data] << new_property[:data]
            vhat_properties[:errors].concat(new_property[:errors])
        }

        return vhat_properties
    end

    ##
    # request_vuids - get a VUID from the rest server
    # @return [object] the generated vuids
    def request_vuids(number_of_vuids = 1, reason = 'Terminology Editor Request')

        vuids = VuidRest.get_vuid_api(action: VuidRestActions::ACTION_ALLOCATE, additional_req_params: {blockSize: number_of_vuids, reason: reason, ssoToken: get_user_token})

        if vuids.is_a? CommonRest::UnexpectedResponse

            error = 'Error getting VUID from server: ' + vuids.rest_exception.conciseMessage
            $log.error(error)
            vuids = {error: error}
        end

        return vuids
    end


end
