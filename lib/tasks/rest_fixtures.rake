require 'fileutils'

module Fixtures
  CONCEPT_DESCRIPTIONS = :concept_descriptions
  CONCEPT_VERSIONS = :concept_versions
  CONCEPT_CHRONOLOGY = :concept_chronology
  TAXONOMY_ROOT = :taxonomy_root
  FILES = {
      CONCEPT_DESCRIPTIONS => "./test/fixtures/concept_description.yml",
      CONCEPT_VERSIONS => "./test/fixtures/concept_version.yml",
      CONCEPT_CHRONOLOGY =>  "./test/fixtures/concept_chronology.yml",
      TAXONOMY_ROOT => "./test/fixtures/isaac_root.yml",
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

  desc "This task hits the isaac rest server. Builds all fixtures."
  task :build => :environment do
    [TAXONOMY_LAMBDA, CONCEPT_LAMBDA ].each(&:call)
  end

end
# bundle exec rake rest_fixtures:build