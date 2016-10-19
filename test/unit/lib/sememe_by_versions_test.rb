# sememe_by_referenced_component_test.rb

#takes UUID
require 'test/unit'
require './config/initializers/01_komet_init'
require './lib/isaac_rest/sememe_rest'
#require './lib/tasks/rest_fixtures.rake'
class SememeVersionsTest < Test::Unit::TestCase
  include KOMETUtilities
  include SememeRest
  include Fixtures

  FAIL_MESSAGE = 'There may be a mismatch between the generated isaac-rest.rb file and rails_komet!: '
  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    #build our isaac_root object from our yaml fixture
    json = YAML.load_file(FILES[Fixtures::SEMEME_VERSIONS])
    @rest_sememe_v = Sememe.new(uuid: TEST_ID, params: nil, body_params: {}, action: ACTION_VERSION, action_constants: ACTION_CONSTANTS).get_rest_class(json).send(:from_json, json)
  end

  def test_build_rest_sememe_by_version
    assert(!@rest_sememe_v.nil?, "The sememe was not properly converted from json to a RestSememeVersion!")
    assert(@rest_sememe_v.kind_of?(Gov::Vha::Isaac::Rest::Api1::Data::Sememe::RestSememeVersion), "The sememe was not properly converted to a RestSememeVersion!")
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

end