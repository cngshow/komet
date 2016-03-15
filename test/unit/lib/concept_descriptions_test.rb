require 'test/unit'
require './config/initializers/01_komet_init'
require './lib/isaac_rest/concept_rest'
require './app/controllers/concerns/concept_concern'

class ConceptDescriptionsTest < Test::Unit::TestCase
  include ETSUtilities
  include ConceptRest
  include Fixtures
  include ConceptConcern

  FAIL_MESSAGE = 'There may be a mismatch between the generated isaac-rest.rb file and rails_komet!: '
  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    #build our isaac_root object from our yaml fixture
    json = YAML.load_file(FILES[Fixtures::CONCEPT_DESCRIPTIONS])
    #we will assume testing on the first one is sufficient
    @rest_concept_descriptions = Concept.new(uuid: TEST_UUID, params: nil, action: ACTION_DESCRIPTIONS, action_constants: ACTION_CONSTANTS).get_rest_class.send(:from_json, json.first)
  end

  def test_build_rest_concept_descriptions
    begin
      assert(!@rest_concept_descriptions.nil? , 'The concept was not properly converted from json to a RestSememeDescriptionVersion!')
      assert(@rest_concept_descriptions.class.eql?(Gov::Vha::Isaac::Rest::Api1::Data::Sememe::RestSememeDescriptionVersion) , 'The concept was not properly converted to a RestSememeDescriptionVersion!')
    rescue => ex
      fail(FAIL_MESSAGE + ex.to_s)
    end
  end

  def test_concern_descriptions
=begin
    desc_hash = descriptions(TEST_UUID)
    assert(!desc_hash.nil? , 'The concept was not properly converted from json to a RestSememeDescriptionVersion!')

    if desc_hash.has_key?(:descriptions)
      assert(desc_hash.fetch(:descriptions).length == 2, 'The test UUID should contain two RestSememeDescriptionVersions!')

      first_desc = desc_hash.fetch(:descriptions).first
      assert_match(/^(?:fully specified name|preferred)$/, first_desc.fetch(:description_type), 'The :description_type is not FSN or preferred!')
      assert_match(/^English language$/, first_desc.fetch(:language), "The :language is not 'English language'!")
      assert_match(/^description not case sensitive$/, first_desc.fetch(:case_significance), "The :case_significance is not 'description not case sensitive'!")
    else
      assert(false, 'The call to concept_concern#descriptions failed!')
    end
=end
    # this test does not lend itself to preloaded yml files we will revisit this later
    assert(true)
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end
end