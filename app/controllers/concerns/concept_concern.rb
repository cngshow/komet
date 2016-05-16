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

require './lib/isaac_rest/concept_rest'
require './lib/isaac_rest/sememe_rest'
require './lib/isaac_rest/id_apis_rest'
require './lib/rails_common/util/helpers'
include KOMETUtilities

module ConceptConcern
  METADATA_HASH = {description_type: 'descriptionTypeConceptSequence',
                   language: 'languageConceptSequence',
                   case_significance: 'caseSignificanceConceptSequence'}

  ##
  # descriptions - takes a uuid and returns all of the description concepts attached to it.
  # @param [String] uuid - The UUID to look up descriptions for
  # @param [Boolean] stated - Whether to display the stated (true) or inferred view of concepts
  # @return [object] an array of hashes that contains the attributes
  def get_attributes(uuid, stated)

    return_attributes = []
    attributes = ConceptRest.get_concept(action: ConceptRestActions::ACTION_VERSION, uuid: uuid, additional_req_params: {expand: 'chronology', stated: stated})

    return_attributes << {label: 'Text', value: attributes.conChronology.description}
    return_attributes << {label: 'State', value: attributes.conVersion.state}
    return_attributes << {label: 'Time', value: DateTime.strptime((attributes.conVersion.time / 1000).to_s, '%s').strftime('%m/%d/%Y')}

    author = description_metadata(attributes.conVersion.authorSequence, stated)

    if author == 'user'
      author = 'System User'
    end

    return_attributes << {label: 'Author', value: author}

    return_attributes << {label: 'Module', value: description_metadata(attributes.conVersion.moduleSequence, stated)}
    return_attributes << {label: 'Path', value: description_metadata(attributes.conVersion.pathSequence, stated)}
    return_attributes << {label: 'UUID', value: uuid}

  end

  ##
  # get_descriptions - takes a uuid and returns all of the description concepts attached to it.
  # @param [String] uuid - The UUID to look up descriptions for
  # @param [Boolean] stated - Whether to display the stated (true) or inferred view of concepts
  # @return [object] a hash that contains an array of all the descriptions
  def get_descriptions(uuid, stated)

    return_descriptions = {uuid: uuid, descriptions: []}
    descriptions = ConceptRest.get_concept(action: ConceptRestActions::ACTION_DESCRIPTIONS, uuid: uuid, additional_req_params: {stated: stated})

    if descriptions.is_a? CommonRest::UnexpectedResponse
      return return_descriptions
    end

    # iterate over the array of Gov::Vha::Isaac::Rest::Api1::Data::Sememe::RestSememeDescriptionVersion returned
    descriptions.each do |description|

      return_description = {text: description.text}
      return_description[:state] =  description.sememeVersion.state

      attributes = []

      # get the description UUID information and add it to the attributes array
      description_uuid = description.sememeChronology.identifiers.uuids.first
      description_state = description.sememeVersion.state
      description_time = DateTime.strptime((description.sememeVersion.time / 1000).to_s, '%s').strftime('%m/%d/%Y')
      description_author = description_metadata(description.sememeVersion.authorSequence, stated)
      description_module = description_metadata(description.sememeVersion.moduleSequence, stated)
      description_path = description_metadata(description.sememeVersion.pathSequence, stated)

      if description_author == 'user'
        description_author = 'System User'
      end

      return_description[:uuid] = description_uuid
      attributes << {label: 'UUID', text: description_uuid, state: description_state, time: description_time, author: description_author, module: description_module, path: description_path}

      # get the description SCTID information if there is one and add it to the attributes array
      sctid = IdAPIsRest.get_id(uuid_or_id: uuid, action: IdAPIsRestActions::ACTION_TRANSLATE, additional_req_params: {outputType: 'sctid'})

      if sctid.respond_to?(:value)


        attributes << {label: 'SCTID', text: sctid.value, state: description_state, time: description_time, author: description_author, module: description_module, path: description_path}

      end


      # loop thru the dialects array, pull out all the language refsets, and add them to the attributes array
      description.dialects.each do |dialect|

        dialect_name = description_metadata(dialect.sememeChronology.assemblageSequence, stated)
        dialect_state = dialect.sememeVersion.state
        dialect_time = DateTime.strptime((dialect.sememeVersion.time / 1000).to_s, '%s').strftime('%m/%d/%Y')
        dialect_author = description_metadata(dialect.sememeVersion.authorSequence, stated)
        dialect_module = description_metadata(dialect.sememeVersion.moduleSequence, stated)
        dialect_path = description_metadata(dialect.sememeVersion.pathSequence, stated)


        if dialect_author == 'user'
          dialect_author = 'System User'
        end

        case dialect_name

          when 'US English dialect'
            dialect_name = 'US English'
        end

        attributes << {label: 'Refset', text: dialect_name, state: dialect_state, time: dialect_time, author: dialect_author, module: dialect_module, path: dialect_path}
      end

      return_description[:attributes] = attributes

      METADATA_HASH.each_pair do |key, value|

       converted_value = description_metadata(description.send(value).to_s, stated)
       return_description[key] = converted_value

        case key

          when :description_type

            case converted_value

              when 'fully specified name'
                return_description[:description_type_short] = 'FSN'

              when 'preferred'
                return_description[:description_type_short] = 'PRE'

              when 'synonym'
                return_description[:description_type_short] = 'SYN'

              when 'definition description type', 'description'
                return_description[:description_type_short] = 'DEF'

              else
                return_description[:description_type_short] = converted_value

            end

          when :language

            case converted_value

              when 'English language'
                return_description[:language_short] = 'EN'

            end

          when :case_significance

            case converted_value

              when 'description initial character sensitive'
                return_description[:case_significance_short] = 'true'

              when 'description case sensitive'
                return_description[:case_significance_short] = 'true'

              when 'description not case sensitive'
                return_description[:case_significance_short] = 'false'

              else
                return_description[:case_significance_short] = 'false'
            end

        end

      end
      return_descriptions[:descriptions] << return_description
    end
    return_descriptions
  end

  ##
  # get_attached_sememes - takes a uuid and returns all of the non-description sememes attached to it.
  # @param [String] uuid - The UUID to look up attached sememes for
  # @param [Boolean] stated - Whether to display the stated (true) or inferred view of concepts
  # @return [object] a hash that contains an array of all the columns to be displayed and an array of all the sememes 
  def get_attached_sememes(uuid, stated)

    sememe_types = {}

    # see if the sememe types object already exists in the session
    if session[:concept_sememe_types]
      #sememe_types = session[:concept_sememe_types]
    end

    sememes = SememeRest.get_sememe(action: SememeRestActions::ACTION_BY_REFERENCED_COMPONENT, uuid_or_id: uuid, additional_req_params: {expand: 'chronology,nestedSememes', stated: stated})

    display_data = process_attached_sememes(stated, sememes, sememe_types, [], [], 1)

    # put the sememe types object into the session
    session[:concept_sememe_types] = display_data[:sememe_types]

    return {columns: display_data[:used_column_list], rows: display_data[:data_rows]}

  end

  ##
  # get_refsets - takes a uuid and returns all of the refset attached to it.
  # @param [String] uuid - The UUID to look up attached sememes for
  # @param [Boolean] stated - Whether to display the stated (true) or inferred view of concepts
  # @return [object] a hash that contains an array of all the columns to be displayed and an array of all the refsets
  def get_refsets(uuid, stated)

    refsets_results = {}
    sememe_types = {}
    page_size = 25
    page_number = params[:taxonomy_refsets_page_number]
    additional_params = {expand: 'chronology,nestedSememes,referencedDetails', pageNum: page_number, stated: stated}
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
  # process_attached_refsets - recursively loops through an array of sememes and processes them for display.
  # @param [RestSememeVersion] sememes - a hash with an array of sememes to process, a cached hash of all unique sememe data, an array of data rows for display, and an array of columns to display
  # @param [Boolean] stated - Whether to display the stated (true) or inferred view of concepts
  # @return [object] a hash that contains an array of all the columns to be displayed and an array of all the refsets
  def process_attached_refsets(stated, sememes, sememe_types, data_rows, used_column_list)

    additional_req_params = {stated: stated}

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
        data_row = {sememe_name: sememe_types[assemblage_sequence][:sememe_name], sememe_description: sememe_types[assemblage_sequence][:sememe_description], uuid: uuid, id: assemblage_sequence, state: {data:sememe.sememeVersion.state,display:''},referencedComponentNidDescription: {data:sememe.sememeChronology.referencedComponentNidDescription,display:''} ,columns: {}}

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
  # process_attached_sememes - recursively loops through an array of sememes and processes them for display.
  # @param [RestSememeVersion] sememes - a hash with an array of sememes to process, a cached hash of all unique sememe data, an array of data rows for display, and an array of columns to display
  # @return [object] a hash that contains an array of all the columns to be displayed and an array of all the sememes 
  def process_attached_sememes(stated, sememes, sememe_types, data_rows, used_column_list, level)

    additional_req_params = {stated: stated}

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

        has_nested = false

        if sememe.nestedSememes != nil && sememe.nestedSememes.length > 0
          has_nested = true
        end

        # start loading the row of sememe data with everything besides the data columns
        data_row = {sememe_name: sememe_types[assemblage_sequence][:sememe_name], sememe_description: sememe_types[assemblage_sequence][:sememe_description], uuid: uuid, id: assemblage_sequence, state: sememe.sememeVersion.state, level: level, has_nested: has_nested, columns: {}}

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
              used_column_list << {id: sememe_column.columnConceptSequence, name: sememe_column.columnName, description: sememe_column.columnDescription, data_type: sememe_column.columnDataType.name}
            end

            data = row_column.data
            converted_value = ''

            # if the column is one of a specific set, make sure it has string data and see if it contains IDs. If it does look up their description
            if (['column name', 'target'].include?(sememe_column.columnName)) && (row_column.data.kind_of? String) && find_ids(row_column.data)

              # the description should be included, but if not look it up
              if row_column.respond_to?('conceptDescription')
                converted_value = row_column.conceptDescription
              else
                converted_value = ConceptRest.get_concept(action: ConceptRestActions::ACTION_DESCRIPTIONS, uuid: row_column.data, additional_req_params: additional_req_params).first.text
              end

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
            data_row[:columns][sememe_column.columnConceptSequence] = {data: data, display: converted_value}

          end

        }

      end

      # if the sememe has nested sememes call this function again passing in those nested sememes and incrementing the level
      if has_nested

        sememes = sememe.nestedSememes
        nested_sememe_data = process_attached_sememes(stated, sememes, sememe_types, [], used_column_list, level + 1)

        data_row[:nested_rows] = nested_sememe_data[:data_rows]

      end

      # add the sememe data row to the array of return rows
      data_rows << data_row

    end

    return {sememe_types: sememe_types, data_rows: data_rows, used_column_list: used_column_list}

  end

  def description_metadata(id, stated)
    ver = ConceptRest.get_concept(action: ConceptRestActions::ACTION_DESCRIPTIONS, uuid: id).first
    ver.text
  end

 # get list of language,dialect and description type in user's preference screen
  def get_languages_dialect(uuid)
    results = {}
    ver = ConceptRest.get_concept(action: ConceptRestActions::ACTION_VERSION, uuid: uuid, additional_req_params: {includeChildren: 'true'})
    results[:children] = ver.children

    return results
  end





end
