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

module TaxonomyRestActions
  ACTION_VERSION = :version
end

module TaxonomyRest
  include TaxonomyRestActions
  include CommonActionSyms
  extend self
  TAXONOMY_PATH = $PROPS['ENDPOINT.isaac_root'] + 'rest/1/taxonomy/'
  VERSION_TAXONOMY_PATH = TAXONOMY_PATH + 'version'
  ISAAC_UUID_PARAM = :id
  #ISAAC_ROOT_ID = 'cc0b2455-f546-48fa-90e8-e214cc8478d6'  #old databases
  ISAAC_ROOT_ID =  '7c21b6c5-cf11-5af9-893b-743f004c97f5'
  VERSION_TAXONOMY_STARTING_PARAMS = {expand: 'chronology', childDepth: 1, parentHeight: 1, countChildren: true, countParents: true}

  ACTION_CONSTANTS = {
      ACTION_VERSION => {PATH_SYM => VERSION_TAXONOMY_PATH, STARTING_PARAMS_SYM => VERSION_TAXONOMY_STARTING_PARAMS, CLAZZ_SYM => Gov::Vha::Isaac::Rest::Api1::Data::Concept::RestConceptVersion},
  }

  class << self
    #attr_accessor :instance_data
  end

  class Taxonomy < CommonRestBase::RestBase
    include CommonRest
    register_rest(rest_module: TaxonomyRest, rest_actions: TaxonomyRestActions)

    attr_accessor :uuid

    def initialize(uuid:, params:, action:, action_constants:)
      @uuid = uuid.to_s unless uuid.nil?
      uuid_check uuid: uuid
      super(params: params, action: action, action_constants: action_constants)
    end

    def rest_call
      p = get_params
      p = {ISAAC_UUID_PARAM => uuid}.merge(p)#p should never be nil it should at least be {}... VERSION_TAXONOMY_STARTING_PARAMS
      url = get_url
      json = rest_fetch(url_string: url, params: p, raw_url: url)
      enunciate_json(json)
    end
  end

#only one action
  def get_isaac_root(additional_req_params: nil)
    Taxonomy.new(uuid: ISAAC_ROOT_ID, params: additional_req_params, action: ACTION_VERSION, action_constants: ACTION_CONSTANTS).rest_call
  end

  def get_isaac_concept(uuid:, additional_req_params: nil)
    Taxonomy.new(uuid: uuid, params: additional_req_params, action: ACTION_VERSION, action_constants: ACTION_CONSTANTS).rest_call
  end

  def main_fetch(**hash)
    get_isaac_concept(uuid: hash[:params]['id'], additional_req_params: hash[:params])
  end

end
# load('./lib/isaac_rest/taxonomy_rest.rb')
# a = TaxonomyRest.get_isaac_root
# b = TaxonomyRest.get_isaac_concept(uuid: 'f7495b58-6630-3499-a44e-2052b5fcf06c')
# c = TaxonomyRest.get_isaac_concept(uuid: ISAAC_ROOT_ID)
# d = TaxonomyRest.get_isaac_concept(uuid: -2146638749)