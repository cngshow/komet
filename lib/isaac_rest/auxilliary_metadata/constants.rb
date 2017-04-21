module AuxilliaryMetadata
  AUXILIARY_METADATA_MAJOR_VERSION = '1'
  AUXILIARY_METADATA_MINOR_VERSION = '0'
  AUXILIARY_METADATA_RELEASE_VERSION = '0'
  AUXILLIARY_VERSION = AUXILIARY_METADATA_MAJOR_VERSION + '.' + AUXILIARY_METADATA_MINOR_VERSION + '.' + AUXILIARY_METADATA_RELEASE_VERSION
  AUXILLIARY_VERSION_KEY = 'AUXILIARY_METADATA_VERSION'
  AUXILIARY_METADATA_FILE = './config/generated/yaml/IsaacMetadataAuxiliary.yaml'

  class << self
    attr_accessor :auxilliary_yaml

    def major_version_ok?
      AuxilliaryMetadata.auxilliary_yaml ||= YAML.load_file(AUXILIARY_METADATA_FILE)
      version = auxilliary_yaml.fetch(AUXILLIARY_VERSION_KEY).to_s
      major_version = version.split('.').first
      AUXILIARY_METADATA_MAJOR_VERSION.eql? major_version
    end

  end

end