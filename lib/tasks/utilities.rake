require 'fileutils'

namespace :utilities do

  desc "This task hits the isaac rest server (it *must* be up) and regenerates the fixture isaac_root.yml"
  task :taxonomy_root_yaml => :environment do
    raise ScriptError.new("This task is only supported in development mode.") unless Rails.env.development?
    require './lib/isaac_rest/taxonomy_rest'
    include ETSUtilities
    isaac_root = TaxonomyRest.get_isaac_root #the simple fact that we fetch the rest data motivates a yaml file's generation in temp.
    file_loc = ETSUtilities::TMP_FILE_PREFIX + url_to_path_string(TaxonomyRest::TAXONOMY_PATH) + ETSUtilities::YML_EXT
    FileUtils.cp(file_loc, "./test/fixtures/isaac_root.yml")
  end
end
