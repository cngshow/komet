require 'fileutils'

module Fixtures
  CONCEPT_DESCRIPTIONS = :concept_descriptions
  CONCEPT_VERSIONS = :concept_versions
  CONCEPT_CHRONOLOGY = :concept_chronology
  TAXONOMY_ROOT = :taxonomy_root
  SEMEME_BY_ASSEMBLAGE = :sememe_assemblage
  SEMEME_VERSIONS = :sememe_versions
  SEMEME_CHRONOLOGY = :sememe_chronolgy
  SEMEME_BY_REFERENCED_COMPONENT = :sememe_ref_comp
  SEMEME_DEFINITION = :sememe_def
  ID_API_TYPES = :id_api_types
  ID_API_TRANSLATE = :id_translate_types
  FILES = {
      CONCEPT_DESCRIPTIONS => "./test/fixtures/concept_description.yml",
      CONCEPT_VERSIONS => "./test/fixtures/concept_version.yml",
      CONCEPT_CHRONOLOGY => "./test/fixtures/concept_chronology.yml",
      TAXONOMY_ROOT => "./test/fixtures/isaac_root.yml",
      SEMEME_BY_ASSEMBLAGE => "./test/fixtures/sememe_by_assemblage.yml",
      SEMEME_VERSIONS => "./test/fixtures/sememe_version.yml",
      SEMEME_CHRONOLOGY => "./test/fixtures/sememe_chronology.yml",
      SEMEME_BY_REFERENCED_COMPONENT => "./test/fixtures/sememe_by_referenced_component.yml",
      SEMEME_DEFINITION => "./test/fixtures/sememe_dynamic_definition.yml",
      ID_API_TYPES => "./test/fixtures/id_api_types.yml",
      ID_API_TRANSLATE => "./test/fixtures/id_api_translate.yml",
  }
end

namespace :rest_fixtures do

  TAXONOMY_LAMBDA = -> do
    include Fixtures
    raise ScriptError.new("This task is only supported in development mode.") unless Rails.env.development?
    include ETSUtilities
    require './lib/isaac_rest/taxonomy_rest'
    #taxonomy set -----
    TaxonomyRest.get_isaac_root #the simple fact that we fetch the rest data motivates a yaml file's generation in temp.
    file_loc = ETSUtilities::TMP_FILE_PREFIX + url_to_path_string(TaxonomyRest::VERSION_TAXONOMY_PATH) + ETSUtilities::YML_EXT
    FileUtils.cp(file_loc, FILES[TAXONOMY_ROOT])
  end

  CONCEPT_LAMBDA = -> do
    include Fixtures
    require './lib/isaac_rest/concept_rest.rb'
    CONCEPT_UUID = ConceptRest::TEST_UUID #What will I do for databases other than vhat?  Will cross that bridge...
    #Descriptions:
    ConceptRest::get_concept(action: ConceptRestActions::ACTION_DESCRIPTIONS, uuid: CONCEPT_UUID) #the simple fact that we fetch the rest data motivates a yaml file's generation in temp.
    file_loc = ETSUtilities::TMP_FILE_PREFIX + url_to_path_string(ConceptRest::DESCRIPTIONS_CONCEPT_PATH) + ETSUtilities::YML_EXT
    FileUtils.cp(file_loc, FILES[CONCEPT_DESCRIPTIONS])
    #Version
    ConceptRest::get_concept(action: ConceptRestActions::ACTION_VERSION, uuid: CONCEPT_UUID) #the simple fact that we fetch the rest data motivates a yaml file's generation in temp.
    file_loc = ETSUtilities::TMP_FILE_PREFIX + url_to_path_string(ConceptRest::VERSION_CONCEPT_PATH) + ETSUtilities::YML_EXT
    FileUtils.cp(file_loc, FILES[CONCEPT_VERSIONS])
    #chronology
    ConceptRest::get_concept(action: ConceptRestActions::ACTION_CHRONOLOGY, uuid: CONCEPT_UUID) #the simple fact that we fetch the rest data motivates a yaml file's generation in temp.
    file_loc = ETSUtilities::TMP_FILE_PREFIX + url_to_path_string(ConceptRest::CHRONOLOGY_CONCEPT_PATH) + ETSUtilities::YML_EXT
    FileUtils.cp(file_loc, FILES[CONCEPT_CHRONOLOGY])
  end

  SEMEME_LAMBDA = -> do
    include Fixtures
    require './lib/isaac_rest/sememe_rest.rb'

    SememeRest::get_sememe(action: SememeRestActions::ACTION_BY_REFERENCED_COMPONENT, uuid_or_id: SememeRest::TEST_UUID_REF_COMP) #the simple fact that we fetch the rest data motivates a yaml file's generation in temp.
    file_loc = ETSUtilities::TMP_FILE_PREFIX + url_to_path_string(SememeRest::BY_REFERENCED_COMPONENT_SEMEME_PATH) + ETSUtilities::YML_EXT
    FileUtils.cp(file_loc, FILES[SEMEME_BY_REFERENCED_COMPONENT])

    SememeRest::get_sememe(action: SememeRestActions::ACTION_CHRONOLOGY, uuid_or_id: SememeRest::TEST_ID) #the simple fact that we fetch the rest data motivates a yaml file's generation in temp.
    file_loc = ETSUtilities::TMP_FILE_PREFIX + url_to_path_string(SememeRest::CHRONOLOGY_SEMEME_PATH) + ETSUtilities::YML_EXT
    FileUtils.cp(file_loc, FILES[SEMEME_CHRONOLOGY])

    SememeRest::get_sememe(action: SememeRestActions::ACTION_VERSION, uuid_or_id: SememeRest::TEST_ID) #the simple fact that we fetch the rest data motivates a yaml file's generation in temp.
    file_loc = ETSUtilities::TMP_FILE_PREFIX + url_to_path_string(SememeRest::VERSION_SEMEME_PATH) + ETSUtilities::YML_EXT
    FileUtils.cp(file_loc, FILES[SEMEME_VERSIONS])

    SememeRest::get_sememe(action: SememeRestActions::ACTION_BY_ASSEMBLAGE, uuid_or_id: SememeRest::TEST_ID) #the simple fact that we fetch the rest data motivates a yaml file's generation in temp.
    file_loc = ETSUtilities::TMP_FILE_PREFIX + url_to_path_string(SememeRest::BY_ASSEMBLAGE_SEMEME_PATH) + ETSUtilities::YML_EXT
    FileUtils.cp(file_loc, FILES[SEMEME_BY_ASSEMBLAGE])

    SememeRest::get_sememe(action: SememeRestActions::ACTION_SEMEME_DEFINITION, uuid_or_id: SememeRest::TEST_UUID_SEMEME_DEF) #the simple fact that we fetch the rest data motivates a yaml file's generation in temp.
    file_loc = ETSUtilities::TMP_FILE_PREFIX + url_to_path_string(SememeRest::DEFINITION_SEMEME_PATH) + ETSUtilities::YML_EXT
    FileUtils.cp(file_loc, FILES[SEMEME_DEFINITION])
  end

  ID_APIS_LAMBDA = -> do
    include Fixtures
    require './lib/isaac_rest/id_apis_rest.rb'

    IdAPIsRest::get_id(action: IdAPIsRestActions::ACTION_TYPES) #the simple fact that we fetch the rest data motivates a yaml file's generation in temp.
    file_loc = ETSUtilities::TMP_FILE_PREFIX + url_to_path_string(IdAPIsRest::TYPES_PATH) + ETSUtilities::YML_EXT
    FileUtils.cp(file_loc, FILES[ID_API_TYPES])

    IdAPIsRest::get_id(action: IdAPIsRestActions::ACTION_TRANSLATE, uuid_or_id: IdAPIsRest::TEST_UUID) #the simple fact that we fetch the rest data motivates a yaml file's generation in temp.
    file_loc = ETSUtilities::TMP_FILE_PREFIX + url_to_path_string(IdAPIsRest::TYPES_TRANSLATE_PATH) + ETSUtilities::YML_EXT
    FileUtils.cp(file_loc, FILES[ID_API_TRANSLATE])
  end

  desc "This task hits the isaac rest server. Builds all fixtures."
  task :build => :environment do
    [TAXONOMY_LAMBDA, CONCEPT_LAMBDA, SEMEME_LAMBDA, ID_APIS_LAMBDA].each(&:call)
  end

end
# bundle exec rake rest_fixtures:build