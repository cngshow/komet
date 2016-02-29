require 'test/unit'
require './config/initializers/01_ets_init'
require './lib/isaac_rest/sememe_rest'
#require './lib/tasks/rest_fixtures.rake'
class SememeChronologyTest < Test::Unit::TestCase
  include ETSUtilities
  include SememeRest
  include Fixtures

  FAIL_MESSAGE = 'There may be a mismatch between the generated isaac-rest.rb file and ets_tooling!: '
  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    #build our isaac_root object from our yaml fixture
    json = YAML.load_file(FILES[Fixtures::SEMEME_CHRONOLOGY])
    @rest_sememe_chron = Sememe.new(uuid: TEST_ID, params: nil, action: ACTION_CHRONOLOGY, action_constants: ACTION_CONSTANTS).get_rest_class.send(:from_json, json)
  end

  def test_build_sememe_concept_chronology
    begin
      assert(!@rest_sememe_chron.nil? , 'The sememe was not properly converted from json to a RestSememeChronology!')
      assert(@rest_sememe_chron.class.eql?(Gov::Vha::Isaac::Rest::Api1::Data::Sememe::RestSememeChronology) , 'The sememe was not properly converted to a RestSememeChronology!')
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