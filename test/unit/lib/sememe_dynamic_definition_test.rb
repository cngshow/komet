# sememe_by_referenced_component_test.rb

#takes UUID
require 'test/unit'
require './config/initializers/01_ets_init'
require './lib/isaac_rest/sememe_rest'
#require './lib/tasks/rest_fixtures.rake'
class SememeDynamicDefinitionTest < Test::Unit::TestCase
  include ETSUtilities
  include SememeRest
  include Fixtures

  FAIL_MESSAGE = "There may be a mismatch betweeen the generated isaac-rest.rb file and ets_tooling!: "
  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    json = YAML.load_file(FILES[Fixtures::SEMEME_DEFINITION])
    @rest_sememe_comp = Sememe.new(uuid: TEST_UUID_SEMEME_DEF, params: nil, action: ACTION_SEMEME_DEFINITION, action_constants: ACTION_CONSTANTS).get_rest_class.send(:from_json, json)
  end

  def test_build_rest_sememe_dynamic_definition
    begin
      assert(!@rest_sememe_comp.nil? , "The sememe was not properly converted from json to a RestDynamicSememeDefinition!")
      assert(@rest_sememe_comp.class.eql?(Gov::Vha::Isaac::Rest::Api1::Data::Sememe::RestDynamicSememeDefinition) , "The sememe was not properly converted to a RestDynamicSememeDefinition!")
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