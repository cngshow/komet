require './lib/isaac_rest/concept_rest'

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
    descriptions.each do |d|
      desc = {text: d.text}

      # dialect = description_metadata(d, 'dialects.sememeChronology.assemblageSequence')

      # desc[:uuid] = convertedValue
      METADATA_HASH.each_pair do |k,v|

       # convertedValue = description_metadata(d, d.send(v).to_s)
        desc[k] = convertedValue

        case k

          when :description_type

            case convertedValue

              when 'fully specified name'
                desc[:description_type_short] = 'FSN'

              when 'preferred'
                desc[:description_type_short] = 'PRE'

              when 'synonym'
                desc[:description_type_short] = 'SYN'

            end

          when :language

            case convertedValue

              when 'English language'
                desc[:language_short] = 'EN'

            end

        end

      end
      ret[:descriptions] << desc
    end
    ret
  end

  private

  def description_metadata(id)
    ver = ConceptRest.get_concept(action: ConceptRestActions::ACTION_DESCRIPTIONS, uuid: id).first
    ver.text
  end
end
