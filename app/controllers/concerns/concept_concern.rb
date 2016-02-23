require './lib/isaac_rest/concept_rest'

module ConceptConcern
  METADATA_HASH = {description_type: 'descriptionTypeConceptSequence',
                   language: 'languageConceptSequence',
                   case_significance: 'caseSignificanceConceptSequence'}

  def descriptions(uuid)
    ret = {uuid: uuid}
    descriptions = ConceptRest.get_concept(action: ConceptRestActions::ACTION_DESCRIPTIONS, uuid: uuid)
    ret[:descriptions] = []

    # iterate over the array of Gov::Vha::Isaac::Rest::Api1::Data::Sememe::RestSememeDescriptionVersion returned
    descriptions.each do |d|
      desc = {text: d.text}
      METADATA_HASH.each_pair do |k,v|
        desc[k] = description_metadata(d, v)
      end
      ret[:descriptions] << desc
    end
    ret
  end

  private

  def description_metadata(rest_sememe_description_version, prop)
    seq = rest_sememe_description_version.send(prop.to_sym).to_s
    ver = ConceptRest.get_concept(action: ConceptRestActions::ACTION_DESCRIPTIONS, uuid: seq).first
    ver.text
  end
end
