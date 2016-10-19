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

    METADATA_HASH = {description_type: 'descriptionTypeConceptSequence',
                     language: 'languageConceptSequence',
                     case_significance: 'caseSignificanceConceptSequence'}

    ##
    # descriptions - takes a uuid and returns all of the description concepts attached to it.
    # @param [String] uuid - The UUID to look up descriptions for
    # @param [Boolean] stated - Whether to display the stated (true) or inferred view of concepts
    # @return [object] an array of hashes that contains the attributes
    def get_attributes(uuid, stated)

        coordinates_token = session[:coordinatestoken].token
        return_attributes = []

        attributes = ConceptRest.get_concept(action: ConceptRestActions::ACTION_VERSION, uuid: uuid, additional_req_params: {coordToken: coordinates_token, expand: 'chronology', stated: stated})

        if attributes.is_a? CommonRest::UnexpectedResponse
            return [{value: ''}, {value: ''}, {value: ''}]
        end

        @concept_text = attributes.conChronology.description
        @concept_state = attributes.conVersion.state.name

        # TODO - remove the hard-coding of type to 'vhat' when the type flags are implemented in the REST APIs
        @concept_terminology_type =  'vhat'

        if attributes.isConceptDefined.nil? || !boolean(attributes.isConceptDefined)
            defined = 'Primitive'
        else
            defined = 'Fully Defined'
        end

        @concept_defined = defined

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
    # @return [object] a hash that contains an array of all the descriptions
    def get_descriptions(uuid, stated)

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
            description_uuid = description.sememeChronology.identifiers.uuids.first
            description_state = description.sememeVersion.state.name
            description_time = DateTime.strptime((description.sememeVersion.time / 1000).to_s, '%s').strftime('%m/%d/%Y')
            description_author = get_concept_metadata(description.sememeVersion.authorSequence)
            description_module = get_concept_metadata(description.sememeVersion.moduleSequence)
            description_path = get_concept_metadata(description.sememeVersion.pathSequence)

            if description_author == 'user'
                description_author = 'System User'
            end

            description_info[:uuid] = description_uuid
            attributes << {label: 'UUID', text: description_uuid, state: description_state, time: description_time, author: description_author, module: description_module, path: description_path}

            # get the description SCTID information if there is one and add it to the attributes array
            sctid = IdAPIsRest.get_id(uuid_or_id: description_uuid, action: IdAPIsRestActions::ACTION_TRANSLATE, additional_req_params: {outputType: 'sctid'})

            if sctid.respond_to?(:value)
                attributes << {label: 'SCTID', text: sctid.value, state: description_state, time: description_time, author: description_author, module: description_module, path: description_path}
            end

            header_dialects = ''

            # loop thru the dialects array, and add them to the attributes array
            description.dialects.each do |dialect|

                dialect_sememe_sequence = dialect.sememeChronology.sememeSequence
                dialect_sememe_id = dialect.sememeChronology.identifiers.uuids.first
                dialect_state = dialect.sememeVersion.state.name
                dialect_time = DateTime.strptime((dialect.sememeVersion.time / 1000).to_s, '%s').strftime('%m/%d/%Y')
                dialect_author = get_concept_metadata(dialect.sememeVersion.authorSequence)
                dialect_module = get_concept_metadata(dialect.sememeVersion.moduleSequence)
                dialect_path = get_concept_metadata(dialect.sememeVersion.pathSequence)
                acceptability_sequence = IdAPIsRest.get_id(uuid_or_id: dialect.dataColumns.first.data, action: IdAPIsRestActions::ACTION_TRANSLATE, additional_req_params: {inputType: 'nid', outputType: 'conceptSequence'}).value

                # TODO switch to using only uuids once REST APIs support it
                dialect_sequence = dialect.sememeChronology.assemblageSequence
                dialect_metadata = find_metadata_by_id(dialect.sememeChronology.assemblageSequence, id_type: 'sequence', return_description: false)
                dialect_id = dialect_metadata['uuids'].first[:uuid]
                dialect_name = dialect_metadata['fsn']

                if dialect_author == 'user'
                    dialect_author = 'System User'
                end

                if header_dialects != ''
                    header_dialects += ' ,'
                end

                header_dialects += dialect_name

                acceptability_metadata = find_metadata_by_id(acceptability_sequence, id_type: 'sequence', return_description: false)
                acceptability_id = acceptability_metadata['uuids'].first[:uuid]
                acceptability_text = acceptability_metadata['fsn']
                header_dialects += ' (' + acceptability_text + ')'

                attributes << {
                    label: 'Dialect',
                    sememe_id: dialect_sememe_id,
                    sememe_sequence: dialect_sememe_sequence,
                    id: dialect_id,
                    sequence: dialect_sequence,
                    text: dialect_name,
                    acceptability_sequence: acceptability_sequence,
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

            METADATA_HASH.each_pair do |key, value|


                converted_value = get_concept_metadata(description.send(value).to_s)
                description_info[key] = converted_value

                case key

                    when :description_type

                        # get the concept uuid from the sequence
                        description_type_id = IdAPIsRest.get_id(uuid_or_id: description.send(value), action: IdAPIsRestActions::ACTION_TRANSLATE, additional_req_params: {inputType: 'conceptSequence', outputType: 'uuid'}).value

                        # make sure the id exits, otherwise just send the sequence
                        if description_type_id.is_a? CommonRest::UnexpectedResponse
                            description_type_id = description.send(value)
                        end

                        description_info[:description_type_sequence] = description.send(value)
                        description_info[:description_type_id] = description_type_id

                        case converted_value

                            when 'fully specified name'
                                description_info[:description_type_short] = 'FSN'

                            when 'preferred'
                                description_info[:description_type_short] = 'PRE'

                            when 'synonym'
                                description_info[:description_type_short] = 'SYN'

                            when 'definition description type', 'description'
                                description_info[:description_type_short] = 'DEF'

                            else
                                description_info[:description_type_short] = converted_value
                        end

                    when :language

                        # get the concept uuid from the sequence
                        language_id = IdAPIsRest.get_id(uuid_or_id: description.send(value), action: IdAPIsRestActions::ACTION_TRANSLATE, additional_req_params: {inputType: 'conceptSequence', outputType: 'uuid'}).value

                        # make sure the id exits, otherwise just send the sequence
                        if language_id.is_a? CommonRest::UnexpectedResponse
                            language_id = description.send(value)
                        end

                        description_info[:language_sequence] = description.send(value)
                        description_info[:language_id] = language_id

                        case converted_value

                            when 'English language'
                                description_info[:language_short] = 'EN'

                        end

                    when :case_significance

                        # get the concept uuid from the sequence
                        case_significance_id = IdAPIsRest.get_id(uuid_or_id: description.send(value), action: IdAPIsRestActions::ACTION_TRANSLATE, additional_req_params: {inputType: 'conceptSequence', outputType: 'uuid'}).value

                        # make sure the id exits, otherwise just send the sequence
                        if case_significance_id.is_a? CommonRest::UnexpectedResponse
                            case_significance_id = description.send(value)
                        end

                        description_info[:case_significance_sequence] = description.send(value)
                        description_info[:case_significance_id] = case_significance_id

                        case converted_value

                            when 'description initial character sensitive'
                                description_info[:case_significance_short] = 'true'

                            when 'description case sensitive'
                                description_info[:case_significance_short] = 'true'

                            when 'description not case sensitive'
                                description_info[:case_significance_short] = 'false'

                            else
                                description_info[:case_significance_short] = 'false'
                        end
                end
            end

            # process nested properties
            if description.nestedSememes.length > 0

                nested_properties = process_attached_sememes(stated, description.nestedSememes, [], {}, 1)
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
    # @return [object] a hash that contains an array of all the associations
    def get_associations(uuid, stated)

        coordinates_token = session[:coordinatestoken].token
        return_associations = []
        additional_req_params = {coordToken: coordinates_token, stated: stated, expand: 'source, target'}

        associations = AssociationRest.get_association(action: AssociationRestActions::ACTION_WITH_SOURCE, uuid_or_id: uuid, additional_req_params: additional_req_params)

        if associations.is_a? CommonRest::UnexpectedResponse
            return return_associations
        end

        # iterate over the array of RestAssociationItemVersion returned
        associations.each do |association|

            id = association.identifiers.uuids.first
            type_id = association.associationTypeSequence

            type = AssociationRest.get_association(action: AssociationRestActions::ACTION_TYPE, uuid_or_id: type_id, additional_req_params: {coordToken: coordinates_token, stated: stated})

            if type.is_a? CommonRest::UnexpectedResponse
                return return_associations
            end

            #type_id = type.identifiers.uuids.first
            type_text = type.description

            target_id = association.targetConcept.identifiers.uuids.first
            target_text = association.targetConcept.description
            # TODO - remove the hard-coding of type to 'vhat' when the type flags are implemented in the REST APIs
            target_taxonomy_type = 'vhat'
            state = association.associationItemStamp.state.name
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
            return_types << {concept_id: type.identifiers.uuids.first, concept_sequence: type.associationConceptSequence, text: type.description}
        end

        return return_types
    end

    ##
    # get_attached_sememes - takes a uuid and returns all of the non-description sememes attached to it.
    # @param [String] uuid - The UUID to look up attached sememes for
    # @param [Boolean] stated - Whether to display the stated (true) or inferred view of concepts
    # @return [object] a hash that contains an array of all the columns to be displayed and an array of all the sememes
    def get_attached_sememes(uuid, stated)

        coordinates_token = session[:coordinatestoken].token

        # see if the sememe types object already exists in the session
        if session[:concept_sememe_types]
            #sememe_types = session[:concept_sememe_types]
        end

        sememes = SememeRest.get_sememe(action: SememeRestActions::ACTION_BY_REFERENCED_COMPONENT, uuid_or_id: uuid, additional_req_params: {coordToken: coordinates_token, expand: 'chronology,nestedSememes', stated: stated})

        display_data = process_attached_sememes(stated, sememes, [], {}, 1)

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
        use_column_list = [];

        display_data = process_attached_refsets(stated, results.results, sememe_types, [],use_column_list)

        refsets_results[:data] = display_data
        refsets_results[:columns] = use_column_list
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
    # get_sememe_definition_details - takes a uuid and returns all of the description concepts attached to it.
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

            assemblage_sequence = sememe_definition.assemblageConceptId

            # use the assemblage sequence to do a concept_description call to get sememe name
            sememe_name = ConceptRest.get_concept(action: ConceptRestActions::ACTION_DESCRIPTIONS, uuid: assemblage_sequence, additional_req_params: additional_req_params).first.text

            # start loading the row of sememe data with everything besides the columns
            data_row = {sememe_name: sememe_name, sememe_description: sememe_definition.sememeUsageDescription, uuid: get_next_id, id: assemblage_sequence, state: 'Active', level: 1, has_nested: false, columns: {}}

            # loop through all of the sememe's columns
            sememe_definition.columnInfo.each{ |row_column|

                # If not added to our hash of columns then add it
                if row_column && ! field_info[row_column.columnConceptSequence]

                    field_info[row_column.columnConceptSequence] = {name: row_column.columnName, description: row_column.columnDescription, data_type: row_column.columnDataType.name, required: row_column.columnRequired, column_used: false}
                    data_row[:columns][row_column.columnConceptSequence] = {}
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
    # @return [object] a hash that contains an array of all the columns to be displayed and an array of all the data
    def process_attached_sememes(stated, sememes, used_column_list, used_column_hash, level)

        coordinates_token = session[:coordinatestoken].token
        additional_req_params = {coordToken: coordinates_token, stated: stated}
        data_rows = []

        # iterate over the array of sememes returned
        sememes.each do |sememe|

            # process dynamic sememe version types
            if sememe.class == Gov::Vha::Isaac::Rest::Api1::Data::Sememe::RestDynamicSememeVersion

                assemblage_sequence = sememe.sememeChronology.assemblageSequence
                uuid = sememe.sememeChronology.identifiers.uuids.first

                # use the assemblage sequence to do a concept_description call to get sememe name, then a sememe_sememeDefinition call to get the columns that sememe has.
                sememe_info = {sememe_name: ConceptRest.get_concept(action: ConceptRestActions::ACTION_DESCRIPTIONS, uuid: assemblage_sequence, additional_req_params: additional_req_params).first.text}
                sememe_definition = SememeRest.get_sememe(action: SememeRestActions::ACTION_SEMEME_DEFINITION, uuid_or_id: assemblage_sequence, additional_req_params: additional_req_params)

                has_nested = false

                if sememe.nestedSememes != nil && sememe.nestedSememes.length > 0
                    has_nested = true
                end

                # start loading the row of sememe data with everything besides the data columns
                data_row = {sememe_name: sememe_info[:sememe_name], sememe_description: sememe_definition.sememeUsageDescription, uuid: uuid, id: assemblage_sequence, state: sememe.sememeVersion.state.name, level: level, has_nested: has_nested, columns: {}}

                # loop through all of the sememe's data columns
                sememe_definition.columnInfo.each{ |row_column|

                    # search to see if we have already added this column to our list of used columns.
                    list_index = used_column_list.find_index {|list_column|
                        list_column[:id] == row_column.columnConceptSequence
                    }

                    # If not added to our list of used columns add it to the end of the list
                    if row_column && !list_index

                        used_column_list << {id: row_column.columnConceptSequence, name: row_column.columnName, description: row_column.columnDescription, data_type: row_column.columnDataType.name, required: row_column.columnRequired, column_used: false}
                        list_index = (used_column_list.length) - 1
                        used_column_hash[row_column.columnConceptSequence] = {name: row_column.columnName, description: row_column.columnDescription, data_type: row_column.columnDataType.name, required: row_column.columnRequired, column_used: false}
                    end

                    data_column = sememe.dataColumns[row_column.columnOrder]
                    column_data = {}

                    # if the column data is not empty process the data
                    if data_column != nil

                        # mark in our column lists that this column has data in at least one row
                        used_column_list[list_index][:column_used] = true
                        used_column_hash[row_column.columnConceptSequence][:column_used] = true

                        data = data_column.data
                        converted_value = ''

                        # if the column is one of a specific set, make sure it has string data and see if it contains IDs. If it does look up their description
                        if (['column name', 'target'].include?(row_column.columnName)) && (data_column.data.kind_of? String) && find_ids(data_column.data)

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
                    data_row[:columns][row_column.columnConceptSequence] = column_data
                }

            end

            # if the sememe has nested sememes call this function again passing in those nested sememes and incrementing the level
            if has_nested

                sememes = sememe.nestedSememes
                nested_sememe_data = process_attached_sememes(stated, sememes, used_column_list, used_column_hash, level + 1)

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

                assemblage_sequence = sememe.sememeChronology.assemblageSequence
                uuid = sememe.sememeChronology.identifiers.uuids.first

                # check to see if our cache already has this sememe type, if not add its info to the cache so we only have to look up once
                if !sememe_types.has_key?(assemblage_sequence)

                    # use the assemblage sequence to do a concept_description call to get sememe name, then a sememe_sememeDefinition call to get the columns that sememe has.
                    sememe_types[assemblage_sequence] = {sememe_name: ConceptRest.get_concept(action: ConceptRestActions::ACTION_DESCRIPTIONS, uuid: assemblage_sequence, additional_req_params: additional_req_params).first.text}
                    sememe_definition = SememeRest.get_sememe(action: SememeRestActions::ACTION_SEMEME_DEFINITION, uuid_or_id: assemblage_sequence, additional_req_params: additional_req_params)

                    sememe_types[assemblage_sequence][:sememe_description] = sememe_definition.sememeUsageDescription
                    sememe_types[assemblage_sequence][:columns] = sememe_definition.columnInfo

                end


                # start loading the row of sememe data with everything besides the data columns
                data_row = {sememe_name: sememe_types[assemblage_sequence][:sememe_name], sememe_description: sememe_types[assemblage_sequence][:sememe_description], uuid: uuid, id: assemblage_sequence, state: {data:sememe.sememeVersion.state.name,display:''},referencedComponentNidDescription: {data:sememe.sememeChronology.referencedComponentNidDescription,display:''} ,columns: {}}

                # loop through all of the sememe's data columns
                sememe.dataColumns.each{|row_column|

                    # make sure the column is not empty
                    if row_column != nil && sememe_types[assemblage_sequence][:columns][row_column.columnNumber] != nil

                        sememe_column = sememe_types[assemblage_sequence][:columns][row_column.columnNumber]

                        # search to see if we have already added this column to our list of used columns.
                        is_column_used = used_column_list.find_index {|list_column|
                            list_column[:id] == sememe_column.columnConceptSequence
                        }

                        # If not added to our list of used columns add it to the end of the list
                        if sememe_column && !is_column_used
                            used_column_list << {id:sememe_column.columnConceptSequence, field: sememe_column.columnName, headerName: sememe_column.columnName, data_type: sememe_column.columnDataType.name}
                        end

                        data = row_column.data
                        converted_value = ''

                        # if the column is one of a specific set, make sure it has string data and see if it contains IDs. If it does look up their description
                        if (['column name', 'target'].include?(sememe_column.columnName)) && (row_column.data.kind_of? String) && find_ids(row_column.data)
                            converted_value = ConceptRest.get_concept(action: ConceptRestActions::ACTION_DESCRIPTIONS, uuid: row_column.data, additional_req_params: additional_req_params).first.text

                            # if the row is an array get the text values into a more readable form
                        elsif row_column.data.kind_of? Array

                            # loop through each item in the array and generate a comma separated list of values
                            row_column.data.each_with_index { |item, index|

                                separator = ', '

                                if index == 0
                                    data = '';
                                    separator = ''
                                end

                                data += separator + item['data'].to_s
                            }

                        end

                        # add the sememe column id and data to the sememe data row
                        data_row[sememe_column.columnName]= {data: data, display: converted_value}

                    end

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
    # @param [String] uuid - The UUID to look up children for
    # @return [object] an array of children
    def get_direct_children(uuid)

        concepts = ConceptRest.get_concept(action: ConceptRestActions::ACTION_VERSION, uuid: uuid, additional_req_params: {includeChildren: 'true'})

        if concepts.is_a? CommonRest::UnexpectedResponse
            return [];
        end

        return concepts.children
    end

end
