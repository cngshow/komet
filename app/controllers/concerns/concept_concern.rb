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
  # @return [object] a hash that contains an array of all the descriptions
  def descriptions(uuid)

    return_descriptions = {uuid: uuid}
    return_descriptions[:descriptions] = []
    descriptions = ConceptRest.get_concept(action: ConceptRestActions::ACTION_DESCRIPTIONS, uuid: uuid)

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
      description_date = DateTime.strptime((description.sememeVersion.time / 1000).to_s, '%s').strftime('%m/%d/%Y')
      description_author = description_metadata(description.sememeVersion.authorSequence)

      if description_author == 'user'
        description_author = 'System User'
      end

      return_description[:uuid] = description_uuid
      attributes << {label: 'Generated UUID', text: description_uuid, date: description_date, author: description_author}

      # get the description SCTID information if there is one and add it to the attributes array
      sctid = IdAPIsRest.get_id(uuid_or_id: uuid, action: IdAPIsRestActions::ACTION_TRANSLATE, additional_req_params: {outputType: 'sctid'})

      if sctid.respond_to?(:value)

        sctid_date = description_date
        sctid_author = description_author

        attributes << {label: 'SCTID', text: sctid.value, date: sctid_date, author: sctid_author}

      end


      # loop thru the dialects array, pull out all the language refsets, and add them to the attributes array
      description.dialects.each do |dialect|

        refset_name = description_metadata(dialect.sememeChronology.assemblageSequence)
        refset_date = DateTime.strptime((dialect.sememeVersion.time / 1000).to_s, '%s').strftime('%m/%d/%Y')
        refset_author = description_metadata(dialect.sememeVersion.authorSequence)

        if refset_author == 'user'
          refset_author = 'System User'
        end

        case refset_name

          when 'US English dialect'
            refset_name = 'US English'
        end

        attributes << {label: 'Refset', text: refset_name, date: refset_date, author: refset_author}
      end

      return_description[:attributes] = attributes

      METADATA_HASH.each_pair do |key, value|

       converted_value = description_metadata(description.send(value).to_s)
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
  # sememes - takes a uuid and returns all of the non-description sememes attached to it.
  # @param [String] uuid - The UUID to look up attached sememes for
  # @return [object] a hash that contains an array of all the descriptions
  def sememes(uuid)

    sememe_types = {}
    data_rows = []
    used_column_list = []

    # see if the sememe types object already exists in the session
    if session[:concept_sememe_types]
      #sememe_types = session[:concept_sememe_types]
    end

    sememes = SememeRest.get_sememe(action: SememeRestActions::ACTION_BY_REFERENCED_COMPONENT, uuid_or_id: uuid, additional_req_params: {expand: 'chronology,nestedSememes'})

    # iterate over the array of sememes returned
    sememes.each do |sememe|

      # process dynamic sememe version types
      if sememe.class == Gov::Vha::Isaac::Rest::Api1::Data::Sememe::RestDynamicSememeVersion

        assemblage_sequence = sememe.sememeChronology.assemblageSequence

        # check to see if our cache already has this sememe type, if not add its info to the cache so we only have to look up once
        if !sememe_types.has_key?(assemblage_sequence)

          # use the assemblageSequence to do a concept_description call to get sememe name, then a sememe_sememeDefinition call to get the columns that sememe has.
          sememe_types[assemblage_sequence] = {sememe_name: ConceptRest.get_concept(action: ConceptRestActions::ACTION_DESCRIPTIONS, uuid: assemblage_sequence).first.text}
          sememe_definition = SememeRest.get_sememe(action: SememeRestActions::ACTION_SEMEME_DEFINITION, uuid_or_id: assemblage_sequence)

          sememe_types[assemblage_sequence][:sememe_description] = sememe_definition.sememeUsageDescription
          sememe_types[assemblage_sequence][:columns] = sememe_definition.columnInfo

        end

        # start loading the row of sememe data with everything besides the data columns
        data_row = {sememe_name: sememe_types[assemblage_sequence][:sememe_name], sememe_description: sememe_types[assemblage_sequence][:sememe_description], state: sememe.sememeVersion.state, columns: {}}

        # loop through all of the sememe's data columns
        sememe.dataColumns.each{|row_column|

          # make sure the column is not empty
          if row_column != nil && sememe_types[assemblage_sequence][:columns][row_column.columnNumber] != nil

            sememe_column = sememe_types[assemblage_sequence][:columns][row_column.columnNumber]

            # search to see if we have already added this column to our list of used columns.
            is_column_used = used_column_list.find {|list_column|
              list_column[:id] == sememe_column.columnConceptSequence
            }

            # If not added to our list of used columns add it to the end of the list
            if sememe_column && !is_column_used
              used_column_list << {id: sememe_column.columnConceptSequence, name: sememe_column.columnName, description: sememe_column.columnDescription}
            end

            data = row_column.data
            converted_value = ''

            # if the column is one of a specific set, make sure it has string data and see if it contains IDs. If it does look up their description
            if (['column name'].include?(sememe_column.columnName)) && (row_column.data.kind_of? String) && find_ids(row_column.data)
              converted_value = ConceptRest.get_concept(action: ConceptRestActions::ACTION_DESCRIPTIONS, uuid: row_column.data).first.text

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

        # add the sememe data row to the array of return rows
        data_rows << data_row

      end

    end

    # put the sememe types object into the session
    session[:concept_sememe_types] = sememe_types

    return {columns: used_column_list, rows: data_rows}

  end

  private

  def description_metadata(id)
    ver = ConceptRest.get_concept(action: ConceptRestActions::ACTION_DESCRIPTIONS, uuid: id).first
    ver.text
  end
end
