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
require './lib/isaac_rest/isaac-rest.rb'
require './lib/ets_common/util/helpers'

#include ETSUtilities

module TaxonomyRest
  include ETSUtilities
  extend self
  TAXONOMY_PATH = $PROPS['ENDPOINT.isaac_root'] + "rest/1/taxonomy/version"
  ISAAC_UUID_PARAM = :id
  ISAAC_ROOT_ID = "cc0b2455-f546-48fa-90e8-e214cc8478d6"
  TAXONOMY_PARAMS_ROOT = {expand: :chronology}
  TAXONOMY_CHILD_PARAMS_BASE = {childDepth: 2}
  @params = {}

  @conn = Faraday.new(:url => @params[:site]) do |faraday|
    faraday.request :url_encoded # form-encode POST params
    faraday.use Faraday::Response::Logger, $log
    faraday.headers['Accept'] = 'application/json'
    #faraday.use Faraday::Middleware::ParseJson
    faraday.adapter :net_http # make requests with Net::HTTP
    #faraday.request  :basic_auth, @urls[:user], @urls[:password]
  end

  class << self
    #attr_accessor :instance_data
  end

  def get_isaac_root
    get_isaac_concept(ISAAC_ROOT_ID, TAXONOMY_PARAMS_ROOT)
  end

  def get_isaac_concept(uuid, additional_req_params = nil)

    params = TAXONOMY_CHILD_PARAMS_BASE.clone.merge!({ISAAC_UUID_PARAM => uuid})
    params.merge!(additional_req_params) if additional_req_params
    response = @conn.get do |req|
      req.url TAXONOMY_PATH
      req.params = params
    end
    json = JSON.parse response.body
    json_to_yaml_file(json, url_to_path_string(TAXONOMY_PATH))
    Gov::Vha::Isaac::Rest::Api1::Data::Concept::RestConceptVersion.from_json(json)
    #puts "-----> " + a["data"]["appName"]
  end


end
# load('./lib/isaac_rest/taxonomy_rest.rb')
# a = TaxonomyRest.get_isaac_concept
# b = TaxonomyRest.get_isaac_concept({id: 'f7495b58-6630-3499-a44e-2052b5fcf06c'})