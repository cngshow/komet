require 'test/unit'
require './config/initializers/01_ets_init'
require './lib/isaac_rest/id_apis_rest'
#require './lib/tasks/rest_fixtures.rake'
class IdApisTranslate < Test::Unit::TestCase
  include ETSUtilities
  include IdAPIsRest
  include Fixtures

  FAIL_MESSAGE = 'There may be a mismatch between the generated isaac-rest.rb file and ets_tooling!: '
  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    #build our object from our yaml fixture
    json = YAML.load_file(FILES[Fixtures::ID_API_TRANSLATE])
    @rest_id_translate = IdAPIs.new(uuid: TEST_UUID, params: nil, action: ACTION_TRANSLATE, action_constants: ACTION_CONSTANTS).get_rest_class.send(:from_json, json)
  end

  def test_build_rest_id_translate
    begin
      assert(@rest_id_translate.class.eql? Gov::Vha::Isaac::Rest::Api1::Data::RestId )
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