=begin
Copyright Notice

 This is a work of the U.S. Government and is not subject to copyright
 protection in the United States. Foreign copyrights may apply.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
=end
require 'test/unit'
require './config/initializers/01_komet_init'
require './lib/isaac_rest/system_apis_rest'

class SystemApiTests < Test::Unit::TestCase
  include KOMETUtilities
  include Fixtures
  include SystemApis

  self.test_order = :defined #run tests in order they appear in this file
  #~ self.test_order = :random
  #~ self.test_order = :alphabetic #default

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
  end

  def test_system_api
    tests = [
        {name: SYSTEM_API_OBJECT_CHRONOLOGY_TYPE, file: FILES[Fixtures::SYSTEM_API_OBJECT_CHRONOLOGY_TYPE], action: ACTION_OBJECT_CHRONOLOGY_TYPE},
        {name: SYSTEM_API_SEMEME_TYPE, file: FILES[Fixtures::SYSTEM_API_SEMEME_TYPE], action: ACTION_SEMEME_TYPE},
        {name: SYSTEM_API_DYNAMIC_SEMEME_VALIDATOR_TYPE, file: FILES[Fixtures::SYSTEM_API_DYNAMIC_SEMEME_VALIDATOR_TYPE], action: ACTION_DYNAMIC_SEMEME_VALIDATOR_TYPE},
        {name: SYSTEM_API_DYNAMIC_SEMEME_DATA_TYPE, file: FILES[Fixtures::SYSTEM_API_DYNAMIC_SEMEME_DATA_TYPE], action: ACTION_DYNAMIC_SEMEME_DATA_TYPE},
    ]

    tests.each do |config|
      json = YAML.load_file(config.fetch(:file))
      types = []

      json.each do |j|
        type = SystemApi.new(action: config.fetch(:action), action_constants: ACTION_CONSTANTS).get_rest_class.send(:from_json, j)
        types << type
      end
      assert(!types.empty?, "The #{config.fetch(:name)} rest response should not be empty!")
      names = types.map { |o| o.name }
      assert(names.include?('Unknown'), "The #{config.fetch(:name)} rest response does not contain the name 'Unknown'")
    end

  end

  # Called after every test method runs. Can be used to tear down fixture information.
  def teardown
    # Do nothing
  end
end
