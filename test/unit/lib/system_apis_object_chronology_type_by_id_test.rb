# system_apis_object_chronology_type_by_id.rb

#takes UUID
require 'test/unit'
require './config/initializers/01_komet_init'
require './lib/isaac_rest/system_apis_rest'

class SystemObjectChronologyByID < Test::Unit::TestCase
  include KOMETUtilities
  include SystemApis
  include Fixtures

  FAIL_MESSAGE = 'There may be a mismatch between the generated isaac-rest.rb file and rails_komet!: '
  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    #build our isaac_root object from our yaml fixture
    json = YAML.load_file(FILES[Fixtures::SYSTEM_API_OBJECT_CHRONOLOGY_TYPE_BY_ID])
    @rest_system_object_chronology_type_by_id = SystemApi.new(uuid: TEST_UUID, action: ACTION_OBJECT_CHRONOLOGY_TYPE_BY_ID, action_constants: ACTION_CONSTANTS).get_rest_class(json).send(:from_json, json)
  end

  def test_build_rest_system_object_chronology_type_by_id
    assert(!@rest_system_object_chronology_type_by_id.nil?, "The sememe was not properly converted from json to a RestObjectChronologyType!")
    assert(@rest_system_object_chronology_type_by_id.kind_of?(Gov::Vha::Isaac::Rest::Api1::Data::Enumerations::RestObjectChronologyType), "The sememe was not properly converted to a RestObjectChronologyType!")
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

end