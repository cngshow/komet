require 'test/unit'
require './config/initializers/01_komet_init'
require './lib/isaac_rest/taxonomy_rest'
#require './lib/tasks/rest_fixtures.rake'

class TaxonomyRestTests < Test::Unit::TestCase

  include KOMETUtilities
  include Fixtures
  include TaxonomyRest
  self.test_order = :defined #run tests in order they appear in this file
  #~ self.test_order = :random
  #~ self.test_order = :alphabetic #default

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    #build our isaac_root object from our yaml fixture
    json = YAML.load_file(FILES[Fixtures::TAXONOMY_ROOT])
    @rest_concept_version = Taxonomy.new(uuid: ISAAC_ROOT_ID, params: nil, action: ACTION_VERSION, action_constants: ACTION_CONSTANTS).get_rest_class.send(:from_json, json)
  end

  def test_build_rest_concept_version
    begin
      assert(!@rest_concept_version.nil? , "isaac_root.yml is not properly converted from json to a RestConceptVersion!")
      assert(@rest_concept_version.class.eql?(Gov::Vha::Isaac::Rest::Api1::Data::Concept::RestConceptVersion) , "isaac_root.yml is not properly converted to a RestConceptVersion!")
    rescue => ex
      fail("There may be a mismatch between the generated isaac-rest.rb file and isaac_root.yml: #{ex.to_s}")
    end
  end

  def test_isaac_root_has_con_chronology
    assert(!@rest_concept_version.conChronology.nil?, "ISAAC root does not have conChronology data!" )
  end

  def test_isaac_root
    assert(@rest_concept_version.conChronology.description =~ /ISAAC root/i, "ISAAC root was not found!" )
  end

  def test_isaac_root_has_children
    assert(@rest_concept_version.children.length > 0, "ISAAC root has no children!" )
  end

  def test_isaac_root_has_identifiers
    assert(!@rest_concept_version.conChronology.identifiers.nil?, "ISAAC root does not have identifiers data!" )
  end

  def test_isaac_root_has_uuid
    assert(!@rest_concept_version.conChronology.identifiers.uuids.first.nil?, "ISAAC root does not have a uuid!" )
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

end