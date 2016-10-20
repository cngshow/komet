# sememe_by_referenced_component_test.rb

#takes UUID
require 'test/unit'
require './config/initializers/01_komet_init'
require './lib/isaac_rest/sememe_rest'
#require './lib/tasks/rest_fixtures.rake'
class SememeTypeTest < Test::Unit::TestCase
  include KOMETUtilities
  include SememeRest
  include Fixtures

  FAIL_MESSAGE = 'There may be a mismatch between the generated isaac-rest.rb file and rails_komet!: '
  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    #build our isaac_root object from our yaml fixture
    json = YAML.load_file(FILES[Fixtures::SYSTEM_API_SEMEME_TYPE])
    @rest_sememe_v = Sememe.new(uuid: TEST_SEMEME_TYPE_ID, body_params: {}, params: nil, action: ACTION_VERSION, action_constants: ACTION_CONSTANTS).get_rest_class(json.first).send(:from_json, json.first)
  end

  def test_build_rest_sememe_types
    assert(!@rest_sememe_v.nil?, "The sememe was not properly converted from json to a RestSememeType!")
    assert(@rest_sememe_v.kind_of?(Gov::Vha::Isaac::Rest::Api1::Data::Enumerations::RestSememeType), "The sememe was not properly converted to a RestSememeType!")
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

end