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
require './lib/isaac_rest/common_rest'

module CoordinateRestActions
  ACTION_COORDINATES_TOKEN = :coordinates_token
  ACTION_COORDINATES = :coordinates
  ACTION_LANGUAGE_COORDINATE = :language_coordinate
  ACTION_LOGIC_COORDINATE = :logic_coordinate
  ACTION_STAMP_COORDINATE = :stamp_coordinate
  ACTION_TAXONOMY_COORDINATE = :taxonomy_coordinate
end

module CoordinateRest
  include CoordinateRestActions
  include CommonActionSyms
  extend self

  #always name the root_path ROOT_PATH!
  ROOT_PATH = ISAAC_ROOT + 'rest/1/coordinate/'
  COORDINATES_TOKEN_PATH = ROOT_PATH + 'coordinatesToken'
  COORDINATES_PATH = ROOT_PATH + 'coordinates'
  LANGUAGE_COORDINATE_PATH = ROOT_PATH + 'languageCoordinate'
  LOGIC_COORDINATE_PATH = ROOT_PATH + 'logicCoordinate'
  STAMP_COORDINATE_PATH = ROOT_PATH + 'stampCoordinate'
  TAXONOMY_COORDINATE_PATH = ROOT_PATH + 'taxonomyCoordinate'

  ACTION_CONSTANTS = {
      ACTION_COORDINATES_TOKEN => {PATH_SYM => COORDINATES_TOKEN_PATH, STARTING_PARAMS_SYM => {}, CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::RestCoordinatesToken},
      ACTION_COORDINATES => {PATH_SYM => COORDINATES_PATH, STARTING_PARAMS_SYM => {}, CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Coordinate::RestCoordinates},
      ACTION_LANGUAGE_COORDINATE => {PATH_SYM => LANGUAGE_COORDINATE_PATH, STARTING_PARAMS_SYM => {}, CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Coordinate::RestLanguageCoordinate},
      ACTION_LOGIC_COORDINATE => {PATH_SYM => LOGIC_COORDINATE_PATH, STARTING_PARAMS_SYM => {}, CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Coordinate::RestLogicCoordinate},
      ACTION_STAMP_COORDINATE => {PATH_SYM => STAMP_COORDINATE_PATH, STARTING_PARAMS_SYM => {}, CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Coordinate::RestStampCoordinate},
      ACTION_TAXONOMY_COORDINATE => {PATH_SYM => TAXONOMY_COORDINATE_PATH, STARTING_PARAMS_SYM => {}, CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Coordinate::RestTaxonomyCoordinate}
  }

  class << self
    #attr_accessor :instance_data
  end

  class Coordinate < CommonRestBase::RestBase
    include CommonRest
    register_rest(rest_module: CoordinateRest, rest_actions: CoordinateRestActions)

    attr_accessor :uuid

    def initialize(params:, action:, action_constants:)
      super(params: params, action: action, action_constants: action_constants)
    end

    def rest_call
      json = rest_fetch(url_string: get_url, params: get_params, raw_url: get_url)
      enunciate_json(json)
    end
  end

  def main_fetch(**hash)
    get_coordinate(action: hash[:action], additional_req_params: hash[:params])
  end

  def get_coordinate(action:, additional_req_params: nil)
    Coordinate.new(action: action,  params: additional_req_params, action_constants: ACTION_CONSTANTS).rest_call
  end
end

=begin
load('./lib/isaac_rest/coordinate_rest.rb')
a = CoordinateRest::get_coordinate(action: CoordinateRestActions::ACTION_COORDINATES_TOKEN, additional_req_params: {stated: false, descriptionTypePrefs: 'synonym', allowedStates: 'active,inactive'})
b = CoordinateRest::get_coordinate(action: CoordinateRestActions::ACTION_COORDINATES, additional_req_params: {stated: false, descriptionTypePrefs: 'synonym', allowedStates: 'active,inactive'})
c = CoordinateRest::get_coordinate(action: CoordinateRestActions::ACTION_LANGUAGE_COORDINATE) # this is the broken call!!!
d = CoordinateRest::get_coordinate(action: CoordinateRestActions::ACTION_LOGIC_COORDINATE)
e = CoordinateRest::get_coordinate(action: CoordinateRestActions::ACTION_STAMP_COORDINATE)
f = CoordinateRest::get_coordinate(action: CoordinateRestActions::ACTION_TAXONOMY_COORDINATE)



=end
