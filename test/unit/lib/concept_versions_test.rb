require 'test/unit'
require './config/initializers/01_ets_init'
require './lib/isaac_rest/concept_rest'
#require './lib/tasks/rest_fixtures.rake'
class ConceptVersionsTest < Test::Unit::TestCase
  include ETSUtilities
  include ConceptRest
  include Fixtures

  FAIL_MESSAGE = 'There may be a mismatch between the generated isaac-rest.rb file and ets_tooling!: '
  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    #build our isaac_root object from our yaml fixture
    json = YAML.load_file(FILES[Fixtures::CONCEPT_VERSIONS])
    @rest_concept_chronology = Concept.new(uuid: TEST_UUID, params: nil, action: ACTION_VERSION, action_constants: ACTION_CONSTANTS).get_rest_class.send(:from_json, json)
  end

  def test_build_rest_concept_version
    begin
      assert(!@rest_concept_chronology.nil? , "The concept was not properly converted from json to a RestConceptVersion!")
      assert(@rest_concept_chronology.class.eql?(Gov::Vha::Isaac::Rest::Api1::Data::Concept::RestConceptVersion) , "The concept was not properly converted to a RestConceptVersion!")
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