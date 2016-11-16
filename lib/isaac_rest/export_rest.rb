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

module ExportRestActions
  ACTION_EXPORT = :export
end

module ExportRest
  include ExportRestActions
  include CommonActionSyms
  extend self, CommonRestCallbacks

  #always name the root_path ROOT_PATH!
  ROOT_PATH = ISAAC_ROOT + 'rest/1/export/'
  PATH_EXPORT_VETS = ROOT_PATH + 'vetsXML'

  #this is only used on the javascript side by export.js.erb.
  VHAT_EXPORT_PATH ={path: 'rest/1/export/vetsXML', start_date: 'changedAfter', end_date: 'changedBefore', max_end_date: java.lang.Long::MAX_VALUE.to_s}

  PARAMS_EMPTY = {}
  PARAMS_NO_CACHE = CommonRest::CacheRequest::PARAMS_NO_CACHE

  ACTION_CONSTANTS = {
      ACTION_EXPORT => {
          PATH_SYM => PATH_EXPORT_VETS,
          STARTING_PARAMS_SYM => PARAMS_NO_CACHE,
          CLAZZ_SYM => String,#we will not be enunciating the xml
      }
  }
  
  class << self
    #attr_accessor :instance_data
  end

  class Export < CommonRestBase::RestBase
    include CommonRest
    register_rest(rest_module: ExportRest, rest_actions: ExportRestActions)

    def initialize(params:, action:, action_constants:)
      super(params: params, action: action, action_constants: action_constants)
    end

    def rest_call
      xml = rest_fetch(url_string: get_url, params: get_params, raw_url: get_url, enunciate: false, content_type: 'application/xml')
      xml
    end
  end

  def main_fetch(**hash)
    get_workflow(action: hash[:action],  additional_req_params: hash[:params])
  end

  def get_workflow(action:,additional_req_params: nil)
    Export.new(params: additional_req_params, action: action, action_constants: ACTION_CONSTANTS).rest_call.body
  end
end

=begin
load('./lib/isaac_rest/common_rest.rb')
load('./lib/isaac_rest/export_rest.rb')
a =  ExportRest.get_workflow(action: ExportRest::ACTION_EXPORT)
b =  ExportRest.get_workflow(action: ExportRest::ACTION_EXPORT, additional_req_params: {changedAfter: 3.days.ago.to_i*1000, changedBefore: 2.days.ago.to_i*1000})
=end