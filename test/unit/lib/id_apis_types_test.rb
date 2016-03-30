require 'test/unit'
require './config/initializers/01_komet_init'
require './lib/isaac_rest/id_apis_rest'
#load './lib/tasks/rest_fixtures.rake'
class IdApisTypes < Test::Unit::TestCase
  include KOMETUtilities
  include IdAPIsRest
  include Fixtures

  FAIL_MESSAGE = "There may be a mismatch between the generated isaac-rest.rb file and rails_komet!: "
  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    #build our object from our yaml fixture
    json = YAML.load_file(FILES[Fixtures::ID_API_TYPES])
    @rest_id_types = IdAPIs.new(uuid: TEST_UUID, params: nil, action: ACTION_TYPES, action_constants: ACTION_CONSTANTS).get_rest_class(json.first).send(:from_json, json.first)

  end

  def test_build_rest_id_types
    begin
      assert(@rest_id_types.class.eql? Gov::Vha::Isaac::Rest::Api1::Data::Enumerations::RestSupportedIdType)
    rescue => ex
      fail(FAIL_MESSAGE + ex.to_s)
    end
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

end