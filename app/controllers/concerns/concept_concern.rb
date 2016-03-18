require './lib/isaac_rest/concept_rest'
require './lib/isaac_rest/id_apis_rest'

module ConceptConcern
  METADATA_HASH = {description_type: 'descriptionTypeConceptSequence',
                   language: 'languageConceptSequence',
                   case_significance: 'caseSignificanceConceptSequence'}

  def descriptions(uuid)

    ret = {uuid: uuid}
    ret[:descriptions] = []
    descriptions = ConceptRest.get_concept(action: ConceptRestActions::ACTION_DESCRIPTIONS, uuid: uuid)

    if descriptions.is_a? CommonRest::UnexpectedResponse
      return ret
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
      ret[:descriptions] << return_description
    end
    ret
  end

  private

  def description_metadata(id)
    ver = ConceptRest.get_concept(action: ConceptRestActions::ACTION_DESCRIPTIONS, uuid: id).first
    ver.text
  end
end
