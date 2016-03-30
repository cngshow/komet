# sememe_by_referenced_component_test.rb

#takes UUID
require 'test/unit'
require './config/initializers/01_komet_init'
require './lib/isaac_rest/sememe_rest'
#require './lib/tasks/rest_fixtures.rake'
class SememeReferencedComponentTest < Test::Unit::TestCase
  include KOMETUtilities
  include SememeRest
  include Fixtures

  FAIL_MESSAGE = 'There may be a mismatch between the generated isaac-rest.rb file and rails_komet!: '
  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    json = YAML.load_file(FILES[Fixtures::SEMEME_BY_REFERENCED_COMPONENT])
    @rest_sememe_comp = Sememe.new(uuid: TEST_UUID_SEMEME_DEF, params: nil, action: ACTION_BY_REFERENCED_COMPONENT, action_constants: ACTION_CONSTANTS).get_rest_class(json.first).send(:from_json, json.first)
  end

  def test_build_rest_sememe_by_referenced_component
    begin
        assert(!@rest_sememe_comp.nil? , "The sememe was not properly converted from json to a RestSememeVersion!")
        assert(@rest_sememe_comp.kind_of?(Gov::Vha::Isaac::Rest::Api1::Data::Sememe::RestSememeVersion) , "The sememe was not properly converted to a RestSememeVersion!")
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