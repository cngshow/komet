require 'fileutils'

module Fixtures
  CONCEPT_DESCRIPTIONS = :concept_descriptions
  CONCEPT_VERSIONS = :concept_versions
  CONCEPT_CHRONOLOGY = :concept_chronology
  TAXONOMY_ROOT = :taxonomy_root
  SEMEME_BY_ASSEMBLAGE = :sememe_assemblage
  SEMEME_VERSIONS = :sememe_versions
  SEMEME_CHRONOLOGY = :sememe_chronology
  SEMEME_BY_REFERENCED_COMPONENT = :sememe_ref_comp
  SEMEME_DEFINITION = :sememe_def
  SEMEME_TYPE = :sememe_type
  ID_API_TYPES = :id_api_types
  ID_API_TRANSLATE = :id_translate_types
  SYSTEM_API_DYNAMIC_SEMEME_VALIDATOR_TYPE = :system_api_dynamic_sememe_validator_type
  SYSTEM_API_OBJECT_CHRONOLOGY_TYPE = :system_api_object_chronology_type
  SYSTEM_API_SEMEME_TYPE = :system_api_sememe_type
  SYSTEM_API_CONCRETE_DOMAIN_OPERATOR_TYPES = :system_api_concrete_domain_operator_types
  SYSTEM_API_NODE_SEMANTIC_TYPE = :system_api_node_semantic_type
  SYSTEM_API_SUPPORTED_ID_TYPES = :system_api_supported_id_types
  SYSTEM_API_OBJECT_CHRONOLOGY_TYPE_BY_ID = :system_api_object_chronology_type_by_id
  SYSTEM_API_SYSTEM_INFO = :system_api_system_info
  SYSTEM_API_DYNAMIC_SEMEME_DATA_TYPE = :system_api_dynamic_sememe_data_type
  # search descriptions and prefix fixtures
  SEARCH_DESCRIPTIONS = :search_descriptions
  LOGIC_GRAPH_VERSION = :graph_version
  LOGIC_GRAPH_CHRONOLOGY = :graph_chronology
  FILES = {
      CONCEPT_DESCRIPTIONS => './test/fixtures/concept_description.yml',
      CONCEPT_VERSIONS => './test/fixtures/concept_version.yml',
      CONCEPT_CHRONOLOGY => './test/fixtures/concept_chronology.yml',
      TAXONOMY_ROOT => './test/fixtures/isaac_root.yml',
      SEMEME_BY_ASSEMBLAGE => './test/fixtures/sememe_by_assemblage.yml',
      SEMEME_VERSIONS => './test/fixtures/sememe_version.yml',
      SEMEME_CHRONOLOGY => './test/fixtures/sememe_chronology.yml',
      SEMEME_BY_REFERENCED_COMPONENT => './test/fixtures/sememe_by_referenced_component.yml',
      SEMEME_DEFINITION => './test/fixtures/sememe_dynamic_definition.yml',
      SEMEME_TYPE => './test/fixtures/sememe_sememe_type.yml',
      SYSTEM_API_DYNAMIC_SEMEME_VALIDATOR_TYPE => './test/fixtures/system_api_dynamic_sememe_validator_type.yml',
      SYSTEM_API_OBJECT_CHRONOLOGY_TYPE => './test/fixtures/system_api_object_chronology_type.yml',
      SYSTEM_API_SEMEME_TYPE => './test/fixtures/system_api_sememe_type.yml',
      SYSTEM_API_DYNAMIC_SEMEME_DATA_TYPE => './test/fixtures/system_api_dynamic_sememe_data_type.yml',
      SYSTEM_API_CONCRETE_DOMAIN_OPERATOR_TYPES => './test/fixtures/system_api_concrete_domain_operator_types.yml',
      SYSTEM_API_NODE_SEMANTIC_TYPE => './test/fixtures/system_api_node_semantic_type.yml',
      SYSTEM_API_SUPPORTED_ID_TYPES => './test/fixtures/system_api_supported_id_types.yml',
      SYSTEM_API_OBJECT_CHRONOLOGY_TYPE_BY_ID => './test/fixtures/system_api_object_chronology_type_by_id.yml',
      SYSTEM_API_SYSTEM_INFO => './test/fixtures/system_api_system_info.yml',
      ID_API_TYPES => './test/fixtures/id_api_types.yml',
      ID_API_TRANSLATE => './test/fixtures/id_api_translate.yml',
      SEARCH_DESCRIPTIONS => './test/fixtures/search_descriptions.yml',
      LOGIC_GRAPH_VERSION => './test/fixtures/logic_graph_version.yml',
      LOGIC_GRAPH_CHRONOLOGY => './test/fixtures/logic_graph_chronology.yml',
  }
end

namespace :rest_fixtures do

  TAXONOMY_LAMBDA = -> do
    include Fixtures
    raise ScriptError.new('This task is only supported in development mode.') unless Rails.env.development?
    include KOMETUtilities
    require './lib/isaac_rest/taxonomy_rest'
    #taxonomy set -----
    TaxonomyRest.get_isaac_root #the simple fact that we fetch the rest data motivates a yaml file's generation in temp.
    file_loc = KOMETUtilities::TMP_FILE_PREFIX + url_to_path_string(TaxonomyRest::VERSION_TAXONOMY_PATH) + KOMETUtilities::YML_EXT
    FileUtils.cp(file_loc, FILES[TAXONOMY_ROOT])
  end

  CONCEPT_LAMBDA = -> do
    include Fixtures
    require './lib/isaac_rest/concept_rest.rb'
    CONCEPT_UUID = ConceptRest::TEST_UUID #What will I do for databases other than vhat?  Will cross that bridge...
    #Descriptions:
    ConceptRest::get_concept(action: ConceptRestActions::ACTION_DESCRIPTIONS, uuid: CONCEPT_UUID) #the simple fact that we fetch the rest data motivates a yaml file's generation in temp.
    file_loc = KOMETUtilities::TMP_FILE_PREFIX + url_to_path_string(ConceptRest::PATH_DESCRIPTIONS_CONCEPT) + KOMETUtilities::YML_EXT
    FileUtils.cp(file_loc, FILES[CONCEPT_DESCRIPTIONS])
    #Version
    ConceptRest::get_concept(action: ConceptRestActions::ACTION_VERSION, uuid: CONCEPT_UUID) #the simple fact that we fetch the rest data motivates a yaml file's generation in temp.
    file_loc = KOMETUtilities::TMP_FILE_PREFIX + url_to_path_string(ConceptRest::PATH_VERSION_CONCEPT) + KOMETUtilities::YML_EXT
    FileUtils.cp(file_loc, FILES[CONCEPT_VERSIONS])
    #chronology
    ConceptRest::get_concept(action: ConceptRestActions::ACTION_CHRONOLOGY, uuid: CONCEPT_UUID) #the simple fact that we fetch the rest data motivates a yaml file's generation in temp.
    file_loc = KOMETUtilities::TMP_FILE_PREFIX + url_to_path_string(ConceptRest::PATH_CHRONOLOGY_CONCEPT) + KOMETUtilities::YML_EXT
    FileUtils.cp(file_loc, FILES[CONCEPT_CHRONOLOGY])
  end

  SEMEME_LAMBDA = -> do
    include Fixtures
    require './lib/isaac_rest/sememe_rest.rb'

    SememeRest::get_sememe(action: SememeRestActions::ACTION_BY_REFERENCED_COMPONENT, uuid_or_id: SememeRest::TEST_UUID_REF_COMP) #the simple fact that we fetch the rest data motivates a yaml file's generation in temp.
    file_loc = KOMETUtilities::TMP_FILE_PREFIX + url_to_path_string(SememeRest::PATH_BY_REFERENCED_COMPONENT_SEMEME) + KOMETUtilities::YML_EXT
    FileUtils.cp(file_loc, FILES[SEMEME_BY_REFERENCED_COMPONENT])

    a = SememeRest::get_sememe(action: SememeRestActions::ACTION_CHRONOLOGY, uuid_or_id: SememeRest::TEST_ID, additional_req_params: {expand: 'versionsAll'}) #the simple fact that we fetch the rest data motivates a yaml file's generation in temp.
    file_loc = KOMETUtilities::TMP_FILE_PREFIX + url_to_path_string(SememeRest::PATH_CHRONOLOGY_SEMEME) + KOMETUtilities::YML_EXT
    FileUtils.cp(file_loc, FILES[SEMEME_CHRONOLOGY])

    SememeRest::get_sememe(action: SememeRestActions::ACTION_VERSION, uuid_or_id: SememeRest::TEST_SEMEME_TYPE_ID) #the simple fact that we fetch the rest data motivates a yaml file's generation in temp.
    file_loc = KOMETUtilities::TMP_FILE_PREFIX + url_to_path_string(SememeRest::PATH_VERSION_SEMEME) + KOMETUtilities::YML_EXT
    FileUtils.cp(file_loc, FILES[SEMEME_VERSIONS])

    SememeRest::get_sememe(action: SememeRestActions::ACTION_BY_ASSEMBLAGE, uuid_or_id: SememeRest::TEST_ASSEMBLAGE_ID) #the simple fact that we fetch the rest data motivates a yaml file's generation in temp.
    file_loc = KOMETUtilities::TMP_FILE_PREFIX + url_to_path_string(SememeRest::PATH_BY_ASSEMBLAGE_SEMEME) + KOMETUtilities::YML_EXT
    FileUtils.cp(file_loc, FILES[SEMEME_BY_ASSEMBLAGE])

    # SememeRest::get_sememe(action: SememeRestActions::ACTION_SEMEME_DEFINITION, uuid_or_id: '0418a591-f75b-39ad-be2c-3ab849326da9') #the simple fact that we fetch the rest data motivates a yaml file's generation in temp.
    # file_loc = KOMETUtilities::TMP_FILE_PREFIX + url_to_path_string(SememeRest::DEFINITION_SEMEME_PATH) + KOMETUtilities::YML_EXT
    # FileUtils.cp(file_loc, FILES[SEMEME_DEFINITION])

    SememeRest::get_sememe(action: SememeRestActions::ACTION_SEMEME_TYPE, uuid_or_id: SememeRest::TEST_SEMEME_TYPE_ID) #the simple fact that we fetch the rest data motivates a yaml file's generation in temp.
    file_loc = KOMETUtilities::TMP_FILE_PREFIX + url_to_path_string(SememeRest::PATH_TYPE_SEMEME) + KOMETUtilities::YML_EXT
    FileUtils.cp(file_loc, FILES[SEMEME_TYPE])
  end

  LOGIC_GRAPHS_LAMBDA = -> do
    include Fixtures
    require './lib/isaac_rest/logic_graph_rest.rb'

    LogicGraphRest::get_graph(action: LogicGraphRestActions::ACTION_CHRONOLOGY, uuid_or_id: LogicGraphRest::TEST_UUID)
    file_loc = KOMETUtilities::TMP_FILE_PREFIX + url_to_path_string(LogicGraphRest::CHRONOLOGY_PATH) + KOMETUtilities::YML_EXT
    FileUtils.cp(file_loc, FILES[LOGIC_GRAPH_CHRONOLOGY])

    LogicGraphRest::get_graph(action: LogicGraphRestActions::ACTION_VERSION, uuid_or_id: LogicGraphRest::TEST_UUID)
    file_loc = KOMETUtilities::TMP_FILE_PREFIX + url_to_path_string(LogicGraphRest::VERSION_PATH) + KOMETUtilities::YML_EXT
    FileUtils.cp(file_loc, FILES[LOGIC_GRAPH_VERSION])
  end

  ID_APIS_LAMBDA = -> do
    include Fixtures
    require './lib/isaac_rest/id_apis_rest.rb'

    IdAPIsRest::get_id(action: IdAPIsRestActions::ACTION_TYPES) #the simple fact that we fetch the rest data motivates a yaml file's generation in temp.
    file_loc = KOMETUtilities::TMP_FILE_PREFIX + url_to_path_string(IdAPIsRest::TYPES_PATH) + KOMETUtilities::YML_EXT
    FileUtils.cp(file_loc, FILES[ID_API_TYPES])

    IdAPIsRest::get_id(action: IdAPIsRestActions::ACTION_TRANSLATE, uuid_or_id: IdAPIsRest::TEST_UUID) #the simple fact that we fetch the rest data motivates a yaml file's generation in temp.
    file_loc = KOMETUtilities::TMP_FILE_PREFIX + url_to_path_string(IdAPIsRest::TYPES_TRANSLATE_PATH) + KOMETUtilities::YML_EXT
    FileUtils.cp(file_loc, FILES[ID_API_TRANSLATE])
  end

  SYSTEM_API_LAMBDA = -> do
    include Fixtures
    require './lib/isaac_rest/system_apis_rest.rb'

    SystemApis::get_system_api(action: SystemApiActions::ACTION_DYNAMIC_SEMEME_DATA_TYPE) #the simple fact that we fetch the rest data motivates a yaml file's generation in temp.
    file_loc = KOMETUtilities::TMP_FILE_PREFIX + url_to_path_string(SystemApis::PATH_DYNAMIC_SEMEME_DATA_TYPE) + KOMETUtilities::YML_EXT
    FileUtils.cp(file_loc, FILES[SYSTEM_API_DYNAMIC_SEMEME_DATA_TYPE])

    SystemApis::get_system_api(action: SystemApiActions::ACTION_OBJECT_CHRONOLOGY_TYPE)
    file_loc = KOMETUtilities::TMP_FILE_PREFIX + url_to_path_string(SystemApis::PATH_OBJECT_CHRONOLOGY_TYPE) + KOMETUtilities::YML_EXT
    FileUtils.cp(file_loc, FILES[SYSTEM_API_OBJECT_CHRONOLOGY_TYPE])

    SystemApis::get_system_api(action: SystemApiActions::ACTION_DYNAMIC_SEMEME_VALIDATOR_TYPE)
    file_loc = KOMETUtilities::TMP_FILE_PREFIX + url_to_path_string(SystemApis::PATH_DYNAMIC_SEMEME_VALIDATOR_TYPE) + KOMETUtilities::YML_EXT
    FileUtils.cp(file_loc, FILES[SYSTEM_API_DYNAMIC_SEMEME_VALIDATOR_TYPE])

    SystemApis::get_system_api(action: SystemApiActions::ACTION_SEMEME_TYPE)
    file_loc = KOMETUtilities::TMP_FILE_PREFIX + url_to_path_string(SystemApis::PATH_SEMEME_TYPE) + KOMETUtilities::YML_EXT
    FileUtils.cp(file_loc, FILES[SYSTEM_API_SEMEME_TYPE])

    SystemApis::get_system_api(action: SystemApiActions::ACTION_CONCRETE_DOMAIN_OPERATOR_TYPES)
    file_loc = KOMETUtilities::TMP_FILE_PREFIX + url_to_path_string(SystemApis::PATH_CONCRETE_DOMAIN_OPERATOR_TYPES) + KOMETUtilities::YML_EXT
    FileUtils.cp(file_loc, FILES[SYSTEM_API_CONCRETE_DOMAIN_OPERATOR_TYPES])

    SystemApis::get_system_api(action: SystemApiActions::ACTION_NODE_SEMANTIC_TYPE)
    file_loc = KOMETUtilities::TMP_FILE_PREFIX + url_to_path_string(SystemApis::PATH_NODE_SEMANTIC_TYPE) + KOMETUtilities::YML_EXT
    FileUtils.cp(file_loc, FILES[SYSTEM_API_NODE_SEMANTIC_TYPE])

    SystemApis::get_system_api(action: SystemApiActions::ACTION_SUPPORTED_ID_TYPES)
    file_loc = KOMETUtilities::TMP_FILE_PREFIX + url_to_path_string(SystemApis::PATH_SUPPORTED_ID_TYPES) + KOMETUtilities::YML_EXT
    FileUtils.cp(file_loc, FILES[SYSTEM_API_SUPPORTED_ID_TYPES])

    SystemApis::get_system_api(action: SystemApiActions::ACTION_OBJECT_CHRONOLOGY_TYPE_BY_ID)
    file_loc = KOMETUtilities::TMP_FILE_PREFIX + url_to_path_string(SystemApis::PATH_OBJECT_CHRONOLOGY_TYPE_BY_ID) + KOMETUtilities::YML_EXT
    FileUtils.cp(file_loc, FILES[SYSTEM_API_OBJECT_CHRONOLOGY_TYPE_BY_ID])

    SystemApis::get_system_api(action: SystemApiActions::ACTION_SYSTEM_INFO)
    file_loc = KOMETUtilities::TMP_FILE_PREFIX + url_to_path_string(SystemApis::PATH_SYSTEM_INFO) + KOMETUtilities::YML_EXT
    FileUtils.cp(file_loc, FILES[SYSTEM_API_SYSTEM_INFO])
  end

  SEARCH_API_LAMBDA = -> do
    include Fixtures
    require './lib/isaac_rest/search_apis_rest.rb'

    params = {descriptionType: 'fsn', query: 'heart'}
    SearchApis::get_search_api(action: SearchApiActions::ACTION_DESCRIPTIONS, additional_req_params: params)
    file_loc = KOMETUtilities::TMP_FILE_PREFIX + url_to_path_string(SearchApis::PATH_DESCRIPTIONS) + KOMETUtilities::YML_EXT
    FileUtils.cp(file_loc, FILES[SEARCH_DESCRIPTIONS])
  end

  desc 'This task hits the isaac rest server. Builds all fixtures.'
  task :build => :environment do
    raise "Issac root is not defined.  You can set the environment variable ISAAC_ROOT=http://my.isaac.instance.com" if ISAAC_ROOT.empty?
    [TAXONOMY_LAMBDA, CONCEPT_LAMBDA, ID_APIS_LAMBDA, SEMEME_LAMBDA, SEARCH_API_LAMBDA, SYSTEM_API_LAMBDA, LOGIC_GRAPHS_LAMBDA].each(&:call)
  end

end

def find_test_uuid
  ApplicationController.parse_isaac_metadata_auxiliary
  uuids = [] #['b0372953-4f20-58b8-ad04-20c2239c7d4e']
  $isaac_metadata_auxiliary.each do |e|
    next unless e.last.has_key?('uuids'); uuids << e.last['uuids'].first[:uuid]
  end
  good_uuids = []
  uuids.each do |uuid|
    begin
      puts "Trying uuid #{uuid}"
      result = SystemApis::get_system_api(action: SystemApiActions::ACTION_OBJECT_CHRONOLOGY_TYPE_BY_ID, uuid_or_id: 'a63f4bf2-a040-11e5-8994-feff819cdc9f') #the simple fact that we fetch the rest data motivates a yaml file's generation in temp.
      good_uuids << uuid unless result.is_a? CommonRest::UnexpectedResponse
      p result
    rescue => ex
    end
  end
  p good_uuids
end
# bundle exec rake rest_fixtures:build
# load ('./lib/tasks/rest_fixtures.rake')
=begin
 > ["0418a591-f75b-39ad-be2c-3ab849326da9", "ee58e573-f5f0-58ef-99ca-9240d25b3063", "f31f3d89-5a6f-5e1f-81d3-5b68344d96f9", "45021920-9567-11e5-8994-feff819cdc9f", "bca0a686-3516-3daf-8fcf-fe396d13cfad", "eb9a5e42-3cba-356d-b62
3-3ed472e20b30", "1f201994-960e-11e5-8994-feff819cdc9f", "1f20182c-960e-11e5-8994-feff819cdc9f", "fd9d47b7-c0a4-3eea-b3ab-2b5a3f9e888f", "6d345372-d9d6-56c1-86c6-8d7b1ae4ce3f", "edf7b492-732d-5235-9df9-3407be8ac6f7", "f66bc690-
1bcd-513a-8b42-350465c2bf47", "ff6b8bd3-b975-5b64-82b5-5723976d0289", "6423facc-b2c9-5922-9dff-f0abe3a19698"]
=end