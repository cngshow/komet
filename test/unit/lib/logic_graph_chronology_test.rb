require 'test/unit'
require './config/initializers/01_komet_init'
require './lib/isaac_rest/logic_graph_rest'
#require './lib/tasks/rest_fixtures.rake'
class LogicGraphChronologyTest < Test::Unit::TestCase
  include KOMETUtilities
  include LogicGraphRest
  include Fixtures

  FAIL_MESSAGE = 'There may be a mismatch between the generated isaac-rest.rb file and rails_komet!: '
  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    #build our object from our yaml fixture
    json = YAML.load_file(FILES[Fixtures::LOGIC_GRAPH_CHRONOLOGY])
    @rest_graph_version = LogicGraph.new(uuid: TEST_UUID, params: nil, action: ACTION_CHRONOLOGY, action_constants: ACTION_CONSTANTS).get_rest_class(json).send(:from_json, json)
  end

  def test_build_rest_graph_chronology
    begin
      assert(@rest_graph_version.class.eql? Gov::Vha::Isaac::Rest::Api1::Data::Sememe::RestSememeChronology)
    rescue => ex
      fail(FAIL_MESSAGE + ex.to_s)
    end
  end
#
  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

end