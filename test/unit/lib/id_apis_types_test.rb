require 'test/unit'
require './config/initializers/01_ets_init'
require './lib/isaac_rest/id_apis_rest'
#require './lib/tasks/rest_fixtures.rake'
class IdApisTypes < Test::Unit::TestCase
  include ETSUtilities
  include IdAPIsRest
  include Fixtures

  FAIL_MESSAGE = "There may be a mismatch between the generated isaac-rest.rb file and ets_tooling!: "
  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    #build our object from our yaml fixture
    @rest_id_types = YAML.load_file(FILES[Fixtures::ID_API_TYPES])
  end

  def test_build_rest_id_types
    begin
      expected = ["uuid","nid","conceptSequence","sememeSequence","sctid","vuid"]
      assert((expected - @rest_id_types).length == 0,"Rest ID type mismatch!") #no point in this until the update.  We have no types so no dependence on enunciate.
      # assert(!@rest_id_types.nil? , "The id was not properly converted from json to JSON!")
      # assert(@rest_id_types.class.eql?(Array) , "The id was not properly converted to a JSON object!")
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