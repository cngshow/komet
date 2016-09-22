require 'test/unit'
require './config/initializers/01_komet_init'
require './lib/isaac_rest/sememe_rest'
#require './lib/tasks/rest_fixtures.rake'
class SememeAssemblageTest < Test::Unit::TestCase
  include KOMETUtilities
  include SememeRest
  include Fixtures

  FAIL_MESSAGE = 'There may be a mismatch between the generated isaac-rest.rb file and rails_komet!: '
  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup

  end

  def test_build_rest_sememe_by_assemblage
    begin
      #build our isaac_root object from our yaml fixture
      json = YAML.load_file(FILES[Fixtures::SEMEME_BY_ASSEMBLAGE])
      rest_sememe_assemblage = Sememe.new(uuid: TEST_ID, params: nil, action: ACTION_BY_ASSEMBLAGE, action_constants: ACTION_CONSTANTS).get_rest_class(json).send(:from_json, json)

      #assert(!rest_sememe_assemblage.results.first.nil? , 'There should be at least one sememe returned!') #turns out zero results can happen!
      assert(rest_sememe_assemblage.class.eql?(Gov::Vha::Isaac::Rest::Api1::Data::Sememe::RestSememeVersions) , 'The sememe was not properly converted to a RestSememeVersions!')
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