require 'test/unit'
require './config/initializers/01_komet_init'
require './lib/isaac_rest/auxilliary_metadata/constants'
#require './lib/tasks/rest_fixtures.rake'

class AuxilliaryMetadataTest  < Test::Unit::TestCase

  include AuxilliaryMetadata

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    #build our isaac_root object from our yaml fixture
  end

  def test_version_expected
    assert(AuxilliaryMetadata.major_version_ok? , "The expected major version is #{AUXILIARY_METADATA_MAJOR_VERSION}.  I am being built with #{AuxilliaryMetadata.auxilliary_yaml[AUXILLIARY_VERSION_KEY]}")
  end


  def teardown
    # Do nothing
  end

end