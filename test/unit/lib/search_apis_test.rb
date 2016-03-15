require 'test/unit'
require './config/initializers/01_komet_init'
require './lib/isaac_rest/search_apis_rest'

class SearchTest < Test::Unit::TestCase
  include ETSUtilities
  include SearchApis
  include Fixtures

  FAIL_MESSAGE = 'There may be a mismatch between the generated isaac-rest.rb file and rails_komet!: '
  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
  end

  def test_search_descriptions
    begin
      json = YAML.load_file(FILES[Fixtures::SEARCH_DESCRIPTIONS])
      results = SearchApi.new(params: nil, action: ACTION_DESCRIPTIONS, action_constants: ACTION_CONSTANTS).get_rest_class.send(:from_json, json.first)
      assert(! results.nil? , 'The Search result should not be empty!')
      assert(results.class.eql?(Gov::Vha::Isaac::Rest::Api1::Data::Search::RestSearchResult), 'The search matches should be of type Gov::Vha::Isaac::Rest::Api1::Data::Search::RestSearchResult.') unless  results.nil?
    rescue => ex
      fail(FAIL_MESSAGE + ex.to_s)
    end
  end

  # Called after every test method runs. Can be used to tear down fixture information.
  def teardown
    # Do nothing
  end
end
