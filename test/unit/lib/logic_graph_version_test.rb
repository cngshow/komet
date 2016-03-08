require 'test/unit'
require './config/initializers/01_ets_init'
require './lib/isaac_rest/logic_graph_rest'
#require './lib/tasks/rest_fixtures.rake'
class LogicGraphVersionTest < Test::Unit::TestCase
  include ETSUtilities
  include LogicGraphRest
  include Fixtures

  FAIL_MESSAGE = 'There may be a mismatch between the generated isaac-rest.rb file and ets_tooling!: '
  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    #build our object from our yaml fixture
    json = YAML.load_file(FILES[Fixtures::LOGIC_GRAPH_VERSION])
    @rest_graph_version = LogicGraph.new(uuid: TEST_UUID, params: nil, action: ACTION_VERSION, action_constants: ACTION_CONSTANTS).get_rest_class.send(:from_json, json)
  end

  def test_build_rest_graph_chronology
    begin
      assert(@rest_graph_version.class.eql? Gov::Vha::Isaac::Rest::Api1::Data::Sememe::RestSememeLogicGraphVersion)
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