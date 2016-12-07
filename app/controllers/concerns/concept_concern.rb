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
require './lib/rails_common/util/helpers'
require './app/helpers/application_helper' #build broken w/o this

include KOMETUtilities

module ConceptConcern
    include ApplicationHelper

    ##
    # descriptions - takes a uuid and returns all of the description concepts attached to it.
    # @param [String] uuid - The UUID to look up descriptions for
    # @param [Boolean] stated - Whether to display the stated (true) or inferred view of concepts
    # @param [Boolean] clone - Are we cloning a concept, if so we will not return the terminology IDs
    # @return [object] an array of hashes that contains the attributes
    def get_attributes(uuid, stated, clone = false)

        coordinates_token = session[:coordinatestoken].token
        return_attributes = []

        attributes = ConceptRest.get_concept(action: ConceptRestActions::ACTION_VERSION, uuid: uuid, additional_req_params: {coordToken: coordinates_token, expand: 'chronology', stated: stated})

        if attributes.is_a? CommonRest::UnexpectedResponse
            return [{value: ''}, {value: ''}, {value: ''}]
        end

        @concept_text = attributes.conChronology.description
        @concept_state = attributes.conVersion.state.enumName

        # TODO - remove the hard-coding of type to 'vhat' when the type flags are implemented in the REST APIs
        @concept_terminology_type =  'vhat'

        if attributes.isConceptDefined.nil? || !boolean(attributes.isConceptDefined)
            defined = 'Primitive'
        else
            defined = 'Fully Defined'
        end

        @concept_defined = defined

        if !clone

            # get the concept SCTID information if there is one
            coding_id = IdAPIsRest.get_id(uuid_or_id: uuid, action: IdAPIsRestActions::ACTION_TRANSLATE, additional_req_params: {outputType: 'sctid'})

            if coding_id.respond_to?(:value)
                @terminology_id = {label: 'SCTID', value: coding_id.value}
            else

                # else get the concept VUID information if there is one
                coding_id = IdAPIsRest.get_id(uuid_or_id: uuid, action: IdAPIsRestActions::ACTION_TRANSLATE, additional_req_params: {outputType: 'vuid'})

                if coding_id.respond_to?(:value)
                    @terminology_id = {label: 'VUID', value: coding_id.value}
                end
            end
        end

        return_attributes << {label: 'Time', value: DateTime.strptime((attributes.conVersion.time / 1000).to_s, '%s').strftime('%m/%d/%Y')}

        author = get_concept_metadata(attributes.conVersion.authorSequence)

        if author == 'user'
            author = 'System User'
        end

        return_attributes << {label: 'Author', value: author}

        return_attributes << {label: 'Module', value: get_concept_metadata(attributes.conVersion.moduleSequence)}
        return_attributes << {label: 'Path', value: get_concept_metadata(attributes.conVersion.pathSequence)}

        return return_attributes
    end

    ##
    # get_descriptions - takes a uuid and returns all of the description concepts attached to it.
    # @param [String] uuid - The UUID to look up descriptions for
    # @param [Boolean] stated - Whether to display the stated (true) or inferred view of concepts
    # @param [Boolean] clone - Are we cloning a concept, if so we will replace the description and other sememe IDs with placeholders
    # @return [object] a hash that contains an array of all the descriptions
    def get_descriptions(uuid, stated, clone = false)

        coordinates_token = session[:coordinatestoken].token
        return_descriptions = []
        descriptions = ConceptRest.get_concept(action: ConceptRestActions::ACTION_DESCRIPTIONS, uuid: uuid, additional_req_params: {coordToken: coordinates_token, stated: stated})

        if descriptions.is_a? CommonRest::UnexpectedResponse
            return return_descriptions
        end

        # iterate over the array of Gov::Vha::Isaac::Rest::Api1::Data::Sememe::RestSememeDescriptionVersion returned
        descriptions.each do |description|

            description_info = {text: description.text}

            # TODO - remove the hard-coding of type to 'vhat' when the type flags are implemented in the REST APIs
            description_info[:terminology_type] = 'vhat'

            attributes = []

            # get the description UUID information and add it to the attributes array
            description_id = description.sememeChronology.identifiers.uuids.first
            description_state = description.sememeVersion.state.enumName
            description_time = DateTime.strptime((description.sememeVersion.time / 1000).to_s, '%s').strftime('%m/%d/%Y')
            description_author = get_concept_metadata(description.sememeVersion.authorSequence)
            description_module = get_concept_metadata(description.sememeVersion.moduleSequence)
            description_path = get_concept_metadata(description.sememeVersion.pathSequence)

            if description_author == 'user'
                description_author = 'System User'
            end

            if clone
                description_info[:description_id] = get_next_id
            else
                description_info[:description_id] = description_id
            end

            if !clone

                attributes << {label: 'UUID', text: description_id, state: description_state, time: description_time, author: description_author, module: description_module, path: description_path}

                # get the description SCTID information if there is one and add it to the attributes array
                sctid = IdAPIsRest.get_id(uuid_or_id: description_id, action: IdAPIsRestActions::ACTION_TRANSLATE, additional_req_params: {outputType: 'sctid'})

                if sctid.respond_to?(:value)
                    attributes << {label: 'SCTID', text: sctid.value, state: description_state, time: description_time, author: description_author, module: description_module, path: description_path}
                end
            end

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
                dialect_author = get_concept_metadata(dialect.sememeVersion.authorSequence)
                dialect_module = get_concept_metadata(dialect.sememeVersion.moduleSequence)
                dialect_path = get_concept_metadata(dialect.sememeVersion.pathSequence)
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
            description_info[:description_type] = get_concept_metadata(description_info[:description_type_id])

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

            # process languages
            description_info[:language_id] = description.languageConcept.uuids.first
            description_info[:language] = get_concept_metadata(description_info[:language_id])

            case description_info[:language]

                when 'English language'
                    description_info[:language_short] = 'EN'

                else
                    description_info[:language_short] = description_info[:language]
            end

            # process case
            description_info[:case_significance_id] = description.caseSignificanceConcept.uuids.first
            description_info[:case_significance] = get_concept_metadata(description_info[:case_significance_id])

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

                nested_properties = process_attached_sememes(stated, description.nestedSememes, [], {}, 1, clone)
                description_info[:nested_properties] = {field_info: nested_properties[:used_column_hash], data: nested_properties[:data_rows]}
            end

            return_descriptions << description_info
        end

        return return_descriptions
    end

    ##
    # get_associations - takes a uuid and returns all associations related to it.
    # @param [String] uuid - The UUID to look up associations for
    # @param [Boolean] stated - Whether to display the stated (true) or inferred view of concepts
    # @param [Boolean] clone - Are we cloning a concept, if so we will replace the association IDs with placeholders
    # @return [object] a hash that contains an array of all the associations
    def get_associations(uuid, stated, clone = false)

        coordinates_token = session[:coordinatestoken].token
        return_associations = []
        additional_req_params = {coordToken: coordinates_token, stated: stated, expand: 'source, target'}

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
            type = AssociationRest.get_association(action: AssociationRestActions::ACTION_TYPE, uuid_or_id: type_id, additional_req_params: {coordToken: coordinates_token, stated: stated})

            if type.is_a? CommonRest::UnexpectedResponse
                return return_associations
            end

            type_text = type.description

            target_id = association.targetConcept.identifiers.uuids.first
            target_text = association.targetConcept.description
            # TODO - remove the hard-coding of type to 'vhat' when the type flags are implemented in the REST APIs
            target_taxonomy_type = 'vhat'
            state = association.associationItemStamp.state.enumName
            time = DateTime.strptime((association.associationItemStamp.time / 1000).to_s, '%s').strftime('%m/%d/%Y')
            author = get_concept_metadata(association.associationItemStamp.authorSequence)
            association_module = get_concept_metadata(association.associationItemStamp.moduleSequence)
            path = get_concept_metadata(association.associationItemStamp.pathSequence)

            return_associations << {id: id, type_id: type_id, type_text: type_text, target_id: target_id, target_text: target_text, target_taxonomy_type: target_taxonomy_type, state: state, time: time, author: author, association_module: association_module, path: path}
        end

        return return_associations
    end

    ##
    # get_association_types - returns all of the association types.
    # @return [object] a hash that contains an array of all the association types
    def get_association_types

        coordinates_token = session[:coordinatestoken].token
        return_types = []
        additional_req_params = {coordToken: coordinates_token}

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
    # @param [Boolean] stated - Whether to display the stated (true) or inferred view of concepts
    # @param [Boolean] clone - Are we cloning a concept, if so we will replace the sememe IDs with placeholders
    # @return [object] a hash that contains an array of all the columns to be displayed and an array of all the sememes
    def get_attached_sememes(uuid, stated, clone = false)

        coordinates_token = session[:coordinatestoken].token

        sememes = SememeRest.get_sememe(action: SememeRestActions::ACTION_BY_REFERENCED_COMPONENT, uuid_or_id: uuid, additional_req_params: {coordToken: coordinates_token, expand: 'chronology,nestedSememes', stated: stated})

        display_data = process_attached_sememes(stated, sememes, [], {}, 1, clone)

        return {columns: display_data[:used_column_list], rows: display_data[:data_rows], field_info: display_data[:used_column_hash]}

    end

    ##
    # get_refsets - takes a uuid and returns all of the refset attached to it.
    # @param [String] uuid - The UUID to look up attached sememes for
    # @param [Boolean] stated - Whether to display the stated (true) or inferred view of concepts
    # @return [object] a hash that contains an array of all the columns to be displayed and an array of all the refsets
    def get_refsets(uuid, stated)

        coordinates_token = session[:coordinatestoken].token
        refsets_results = {}
        sememe_types = {}
        page_size = 25
        page_number = params[:taxonomy_refsets_page_number]
        additional_params = {coordToken: coordinates_token, expand: 'chronology,nestedSememes,referencedDetails', pageNum: page_number, stated: stated}
        additional_params[:maxPageSize] =  page_size

        results = SememeRest.get_sememe(action: SememeRestActions::ACTION_BY_ASSEMBLAGE, uuid_or_id: uuid, additional_req_params:additional_params )

        refsets_results[:total_number] = results.paginationData.approximateTotal
        refsets_results[:page_number] = results.paginationData.pageNum
        used_column_list = [];

        display_data = process_attached_refsets(stated, results.results, sememe_types, [], used_column_list)

        refsets_results[:data] = display_data
        refsets_results[:columns] = used_column_list
        return refsets_results
    end

    private

    ##
    # get_sememe_details - takes a uuid and returns all of the description concepts attached to it.
    # @param [String] uuid - The UUID to look up descriptions for
    # @param [Boolean] stated - Whether to display the stated (true) or inferred view of concepts
    # @return [object] a RestSememeVersion object
    def get_sememe_version_details(uuid, stated)

        coordinates_token = session[:coordinatestoken].token
        sememe = SememeRest.get_sememe(action: SememeRestActions::ACTION_VERSION, uuid_or_id: uuid, additional_req_params: {coordToken: coordinates_token, expand: 'chronology,nestedSememes', stated: stated})

        if sememe.is_a? CommonRest::UnexpectedResponse
            return nil
        end

        return sememe
    end

    ##
    # get_sememe_definition_details - takes a sememe uuid and returns all of the description concepts attached to it.
    # @param [String] uuid - The UUID to look up descriptions for
    # @return [object] a RestSememeVersion object
    def get_sememe_definition_details(uuid)

        coordinates_token = session[:coordinatestoken].token
        additional_req_params = {coordToken: coordinates_token}
        data_row = {}
        field_info = {}

        # do a sememe_sememeDefinition call to get the columns that sememe has.

        sememe_definition = SememeRest.get_sememe(action: SememeRestActions::ACTION_SEMEME_DEFINITION, uuid_or_id: uuid, additional_req_params: additional_req_params)

        # process dynamic sememe definition types
        if sememe_definition.class == Gov::Vha::Isaac::Rest::Api1::Data::Sememe::RestDynamicSememeDefinition

            # TODO switch to using only uuids once REST APIs support it, and then no need for description call below
            assemblage_id = sememe_definition.assemblageConceptId.uuids.first
            sememe_name = sememe_definition.assemblageConceptDescription

            # start loading the row of sememe data with everything besides the columns
            data_row = {sememe_name: sememe_name, sememe_description: sememe_definition.sememeUsageDescription, sememe_instance_id: get_next_id, sememe_definition_id: assemblage_id, state: 'Active', level: 1, has_nested: false, columns: {}}

            # loop through all of the sememe's columns
            sememe_definition.columnInfo.each{ |row_column|

                column_id = row_column.columnLabelConcept.uuids.first

                # If not added to our hash of columns then add it
                if row_column && ! field_info[assemblage_id + '_' + column_id]

                    # get the column data type from the validator data if it exists, otherwise use string
                    if row_column.columnDataType.classType
                        data_type_class = row_column.columnDataType.classType
                    else
                        data_type_class = 'gov.vha.isaac.rest.api1.data.sememe.dataTypes.RestDynamicSememeString'
                    end

                    field_info[assemblage_id + '_' + column_id] = {
                        sememe_definition_id: assemblage_id,
                        column_id: column_id,
                        name: row_column.columnName,
                        description: row_column.columnDescription,
                        data_type: row_column.columnDataType.enumName,
                        data_type_class: data_type_class,
                        column_number: row_column.columnOrder,
                        required: row_column.columnRequired,
                        column_used: false
                    }

                    data_row[:columns][column_id] = {}
                end
            }
        end

        return {data: data_row, field_info: field_info}
    end

    ##
    # process_attached_sememes - recursively loops through an array of sememes and processes them for display.
    # @param [Boolean] stated - Whether to display the stated (true) or inferred view of concepts
    # @param [RestSememeVersion] sememes - a hash with an array of sememes to process
    # @param [Array] used_column_list - an array of data columns for display (for easier sequential access)
    # @param [Hash] used_column_hash - a hash of data columns for display (for easier random access)
    # @param [Number] level - the level of recursion we are at.
    # @param [Boolean] clone - Are we cloning a concept, if so we will replace the sememe IDs with placeholders
    # @return [object] a hash that contains an array of all the columns to be displayed and an array of all the data
    def process_attached_sememes(stated, sememes, used_column_list, used_column_hash, level, clone = false)

        coordinates_token = session[:coordinatestoken].token
        additional_req_params = {coordToken: coordinates_token, stated: stated}
        data_rows = []

        # iterate over the array of sememes returned
        sememes.each do |sememe|

            # process dynamic sememe version types
            if sememe.class == Gov::Vha::Isaac::Rest::Api1::Data::Sememe::RestDynamicSememeVersion

                assemblage_id = sememe.sememeChronology.assemblage.uuids.first
                sememe_instance_id = sememe.sememeChronology.identifiers.uuids.first

                # use the assemblage to do a sememe_sememeDefinition call to get the columns that sememe has.
                sememe_definition = SememeRest.get_sememe(action: SememeRestActions::ACTION_SEMEME_DEFINITION, uuid_or_id: assemblage_id, additional_req_params: additional_req_params)

                # if we are cloning a concept then put in a placeholder for the instance ID
                if clone
                    sememe_instance_id = get_next_id
                end

                has_nested = false

                if sememe.nestedSememes != nil && sememe.nestedSememes.length > 0
                    has_nested = true
                end

                # start loading the row of sememe data with everything besides the data columns
                data_row = {sememe_name: sememe_definition.assemblageConceptDescription, sememe_description: sememe_definition.sememeUsageDescription, sememe_instance_id: sememe_instance_id, sememe_definition_id: assemblage_id, state: sememe.sememeVersion.state.enumName, level: level, has_nested: has_nested, columns: {}}

                # loop through all of the sememe's data columns
                sememe_definition.columnInfo.each{ |row_column|

                    column_id = row_column.columnLabelConcept.uuids.first

                    # search to see if we have already added this column to our list of used columns.
                    list_index = used_column_list.find_index {|list_column|
                        list_column[:sememe_definition_id] == assemblage_id && list_column[:column_id] == column_id
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
                            sememe_definition_id: assemblage_id,
                            column_id: column_id,
                            name: row_column.columnName,
                            description: row_column.columnDescription,
                            data_type: row_column.columnDataType.enumName,
                            data_type_class: data_type_class,
                            column_number: row_column.columnOrder,
                            required: row_column.columnRequired,
                            column_used: false
                        }

                        if used_column_data[:sememe_definition_id] == $isaac_metadata_auxiliary['EXTENDED_DESCRIPTION_TYPE']['uuids'].first[:uuid]

                            used_column_data[:column_display] = 'dropdown'
                            used_column_data[:dropdown_options] = get_direct_children('fc134ddd-9a15-5540-8fcc-987bf2af9198', true, true)
                       # elsif used_column_data[:data_type] == 'UUID'

                        else
                            used_column_data[:column_display] = 'text'
                        end

                        used_column_list << used_column_data
                        used_column_hash[assemblage_id + '_' + column_id] = used_column_data
                        list_index = (used_column_list.length) - 1
                    end

                    data_column = sememe.dataColumns[row_column.columnOrder]
                    column_data = {}

                    # if the column data is not empty process the data
                    if data_column != nil

                        # mark in our column lists that this column has data in at least one row
                        used_column_list[list_index][:column_used] = true
                        used_column_hash[assemblage_id + '_' + column_id][:column_used] = true

                        data = data_column.data
                        converted_value = ''

                        # if the column is one of a specific set, make sure it has string data and see if it contains IDs. If it does look up their description
                        if (['column name', 'target'].include?(row_column.columnName) && (data_column.data.kind_of? String) && find_ids(data_column.data)) || (data_column.respond_to?('dataIdentified') && data_column.dataIdentified.type.enumName == 'CONCEPT')

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
                                    data = '';
                                    separator = ''
                                end

                                data += separator + item.data.to_s
                            }

                        end

                        # store the data for the column
                        column_data = {data: data, display: converted_value}
                    end

                    # add the sememe column id and data to the sememe data row
                    data_row[:columns][column_id] = column_data
                }

            end

            # if the sememe has nested sememes call this function again passing in those nested sememes and incrementing the level
            if has_nested

                sememes = sememe.nestedSememes
                nested_sememe_data = process_attached_sememes(stated, sememes, used_column_list, used_column_hash, level + 1, clone)

                data_row[:nested_rows] = nested_sememe_data[:data_rows]

            end

            # add the sememe data row to the array of return rows
            data_rows << data_row

        end

        return {data_rows: data_rows, used_column_list: used_column_list, used_column_hash: used_column_hash }

    end

    ##
    # process_attached_refsets - recursively loops through an array of sememes and processes them for display.
    # @param [RestSememeVersion] sememes - a hash with an array of sememes to process, a cached hash of all unique sememe data, an array of data rows for display, and an array of columns to display
    # @param [Boolean] stated - Whether to display the stated (true) or inferred view of concepts
    # @return [object] a hash that contains an array of all the columns to be displayed and an array of all the refsets
    def process_attached_refsets(stated, sememes, sememe_types, data_rows, used_column_list)

        coordinates_token = session[:coordinatestoken].token
        additional_req_params = {coordToken: coordinates_token, stated: stated}

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
                                    data = '';
                                    separator = ''
                                end

                                data += separator + item.data.to_s
                            }
                        end

                        # store the data for the column
                        column_data = {data: data, display: converted_value}
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
    # descriptions - takes a uuid and returns all of the description concepts attached to it.
    # @param [String] uuid - The UUID to look up descriptions for
    # @param [Boolean] stated - Whether to display the stated (true) or inferred view of concepts
    # @return [object] an array of hashes that contains the attributes
    def get_conceptData(uuid)

        coordinates_token = session[:coordinatestoken].token
        returnConcept_attributes = []

        isaac_concept = TaxonomyRest.get_isaac_concept(uuid: uuid)

        if isaac_concept.is_a? CommonRest::UnexpectedResponse
            return [{value: ''}, {value: ''}, {value: ''}]
        end

        returnConcept_attributes << {label: 'FSN', value: concept.conChronology.description}
        returnConcept_attributes << {label: 'ParentID', value: parent.conChronology.identifiers.uuids.first}
        descriptions = ConceptRest.get_concept(action: ConceptRestActions::ACTION_DESCRIPTIONS, uuid: uuid, additional_req_params: {coordToken: coordinates_token, stated: stated})
        returnConcept_attributes << {label: 'PreferredTerm', value: description.text}

        return returnConcept_attributes

    end

    ##
    # get_concept_children - takes a uuid and returns all of its direct children.
    # @param [String] concept_id - The UUID to look up children for
    # @param [Boolean] format_results - Should the results be processed
    # @param [Boolean] remove_semantic_tag - Should semantic tags be removed (Just 'ISAAC' at the moment)
    # @return [object] an array of children
    def get_direct_children(concept_id, format_results = false, remove_semantic_tag = false)

        children = ConceptRest.get_concept(action: ConceptRestActions::ACTION_VERSION, uuid: concept_id, additional_req_params: {includeChildren: 'true'})

        if children.is_a? CommonRest::UnexpectedResponse
            return [];
        end

        children = children.children

        if format_results

            child_array = []

            children.each do |child|

                text = child.conChronology.description

                # TODO - replace with regex that handles any semantic tag: start with /\s\(([^)]+)\)/ (regex101.com)
                if remove_semantic_tag
                    text.slice!(' (ISAAC)')
                end

                child_array << {concept_id: child.conChronology.identifiers.uuids.first, concept_sequence: child.conChronology.identifiers.sequence, text: text}
            end

            return child_array
        else
            return children
        end

    end

end
