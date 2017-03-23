require './lib/rails_common/util/helpers'
require './lib/rails_common/util/controller_helpers'
require './lib/isaac_rest/enunciate/isaac-rest.rb'
require 'uri'

module CommonRest
  include KOMETUtilities, CommonController

  #make body have the conciseMessage if we have it, otherwise we might have html
  UnexpectedResponse = Struct.new(:body, :status, :rest_exception) do
    include BootstrapNotifier
    def flash_error
      $log.warn("Flashing the error #{self.body}")
      flash_alert(message: self.body)
    end
  end

  #used as your key in the req params to indicate if this request is cached
  module CacheRequest
    PARAMS_NO_CACHE = {CommonRest::CacheRequest => false}
  end

  CONNECTION = Faraday.new do |faraday|

    faraday.request :url_encoded # form-encode POST params
    faraday.use Faraday::Response::Logger, $log
    faraday.headers['Accept'] = 'application/json'
    #faraday.use Faraday::Middleware::ParseJson
    faraday.adapter :net_http # make requests with Net::HTTP
    #faraday.request  :basic_auth, @urls[:user], @urls[:password]
  end

  def self.clear_cache(rest_module:)
    begin
      if rest_module.constants.include?(:ROOT_PATH)
        $rest_cache.clear_cache(key_starts_with: rest_module::ROOT_PATH)
        $log.info("Cache cleared for #{rest_module}")
        true
      end
    rescue => ex
      $log.warn('Did you call the clear cache method with a Rest module with constant ROOT_PATH?  Not doing anything...')
      $log.warn(ex.message)
      $log.warn(ex.backtrace.join("\n"))
      false
    end
  end

  def uuid_check(uuid:)

    if uuid.nil?

      $log.error('The UUID cannot be nil!  Please ensure the caller provides a UUID.')
      raise ArgumentError.new('The UUID cannot be nil!!')
    end
  end

  def rest_fetch(url_string:, params:, body_params: {}, raw_url:, enunciate: true, content_type: 'application/json')

    check_cache = params[CacheRequest]
    check_cache = check_cache.nil? ? true : check_cache
    sending_params = params.clone
    sending_params.delete(CacheRequest)
    http_method = get_http_method

    $log.debug("should cache be used: #{check_cache}; The HTTP Method: #{http_method}")

    if check_cache

      cache_lookup = {url_string => sending_params}

      unless http_method != CommonActionSyms::HTTP_METHOD_GET || $rest_cache[cache_lookup].nil?

        $log.info('Using a cached result!  No rest fetch will occur!')
        $log.info("Cache key: #{cache_lookup}")
        json = $rest_cache[cache_lookup]
        json_to_yaml_file(json, url_to_path_string(raw_url))
        return json.deep_dup
      end
    end

    response = CONNECTION.send http_method do |req|

      req.url url_string
      req.params = sending_params
      req.headers['Content-Type'] = content_type
      req.headers['Accept'] = content_type

      if http_method == CommonActionSyms::HTTP_METHOD_POST || http_method == CommonActionSyms::HTTP_METHOD_PUT
        body_class = ruby_classname_to_java(class_name: action_constants.fetch(action)[CommonActionSyms::BODY_CLASS])
        body_params[:@class] = body_class
        req.body = body_params.to_json
        $log.debug('Body Params: ' + body_params.to_s)
      end
    end

    return response unless enunciate

    json = nil
    begin
      json = JSON.parse response.body
    rescue JSON::ParserError => ex

      if http_method == CommonActionSyms::HTTP_METHOD_GET && response.status.eql?(200)
        $rest_cache[cache_lookup] = response.body
        return response.body
      end

      $log.warn("Invalid JSON returned from ISAAC rest. URL is #{url_string}")
      $log.warn('Result is ' + response.body)
      $log.warn('Status is ' + response.status.to_s)

      return UnexpectedResponse.new(response.body, response.status, nil)
    end
    invoke_callbacks if self.respond_to? :invoke_callbacks #if I have been mixed into an instance of common rest base I will respond to this
    json.freeze
    json_to_yaml_file(json, url_to_path_string(raw_url))
    $rest_cache[cache_lookup] = json unless ((http_method != CommonActionSyms::HTTP_METHOD_GET) || !response.status.eql?(200)) #this should prevent RestExceptionResponse from being cached
    json.deep_dup
  end
end

module CommonActionSyms
  PATH_SYM = :path
  CLAZZ_SYM = :clazz
  STARTING_PARAMS_SYM = :starting_params
  HTTP_METHOD_KEY = :http_method
  HTTP_METHOD_GET = :get
  HTTP_METHOD_PUT = :put
  HTTP_METHOD_POST = :post
  BODY_CLASS = :body_class
  CALLBACKS = :callbacks
end

module CommonRestBase
  class RestBase
    include CommonActionSyms
    attr_accessor :params, :body_params, :action, :action_constants
    include Gov::Vha::Isaac::Rest::Api::Exceptions

    def initialize(params:, body_params: {}, action:, action_constants:)
      body_params = body_params.to_jaxb_json_hash if body_params.respond_to? :to_jaxb_json_hash
      @params = params
      @body_params = body_params
      @action = action
      @action_constants = action_constants
    end

    def invoke_callbacks
      begin
        @action_constants[action][CALLBACKS].each do |c|
          c.call
        end if (@action_constants.key?(action) && @action_constants[action].key?(CALLBACKS))
      rescue => ex
        $log.error("Could not execute a callback.  The remaining callbacks will not be attempted. #{ex}")
        $log.error(ex.backtrace.join("\n"))
      end
    end

    def get_url
      action_constants.fetch(action).fetch(PATH_SYM)
    end

    def get_http_method

      result = action_constants.fetch(action)[HTTP_METHOD_KEY]
      $log.debug("The HTTP verb for action: #{action} is: #{result}")
      result.nil? ? HTTP_METHOD_GET : result
    end

    def get_params
      r_val = action_constants.fetch(action).fetch(STARTING_PARAMS_SYM).clone
      r_val.merge!(params) unless params.nil?
      r_val
    end

    def get_rest_class(json)

      if json.nil? || json['@class'].nil?
        clazz = action_constants.fetch(action).fetch(CLAZZ_SYM)
      else

        clazz_array_parts = json['@class'].split('.')
        short_clazz = clazz_array_parts.pop

        clazz_package = clazz_array_parts.map do |e|
          e[0] = e.first.capitalize; e
        end.join('::')

        clazz = clazz_package + '::' + short_clazz
        clazz = Object.const_get clazz
        $log.debug('Using the class from the json it is ' + clazz.to_s)
        $log.debug('It would have been ' + action_constants.fetch(action).fetch(CLAZZ_SYM).to_s)
      end
      clazz
    end

    def rest_call
      raise NotImplementedError.new('You need to implement me in your base class!')
    end

    def convert_java_to_ruby(_item)

    end

    #see https://github.com/stoicflame/enunciate/
    def enunciate_json(json)

      if json.class.eql?(CommonRest::UnexpectedResponse)
        return json
      end

      r_val = nil

      if json.is_a? Array

        r_val = []

        json.each do |elem|
          clazz = get_rest_class(elem)
          r_val.push(clazz.send(:from_json, elem))
        end
      else

        clazz = get_rest_class(json)
        r_val = clazz.send(:from_json, json)
      end
      if r_val.is_a? RestExceptionResponse

        $log.warn("A RestExceptionResponse response was sent from ISAAC. Message is #{r_val.verboseMessage}, status was #{r_val.status}")
        r_val = CommonRest::UnexpectedResponse.new(r_val.conciseMessage, r_val.status, r_val )
      end
      r_val
    end

    def self.register_rest(rest_module:, rest_actions:)

      @@rest_modules ||= {}
      paths = {}

      unless @@rest_modules.has_key? rest_module

        hash = rest_module.const_get :ACTION_CONSTANTS

        rest_actions.constants.each do |c|
          c = rest_actions.const_get c
          path = hash[c][PATH_SYM]
          paths[c] = path
        end

        @@rest_modules[rest_module] = paths
      end

      $log.debug('Registered modules:')
      $log.debug(@@rest_modules.to_s)
    end

    def self.invoke(url:)

      $log.debug('invoke')
      isaac_root_url = ISAAC_ROOT
      uri = nil
      action = nil
      module_ = nil
      params = {}
      id = nil
      invocation_found = false

      begin

        uri = URI(url)
        params = Hash[URI.decode_www_form(uri.query)] unless uri.query.nil?
        #issac_root is supposed to always end in a slash! So...
        url = isaac_root_url + uri.path
        # strip out any double slashes except the http(s)://
        url.gsub!('//', '^').gsub!(/:\^/, '://').gsub!('^', '/')
        $log.debug("Url is #{url}")

      rescue URI::InvalidURIError => ex

        $log.error("An invalid URL was given!  No further attempt to obtain data will be made! URL = #{url}")
        $log.error(ex.to_s)
        return
      end

      @@rest_modules.each_pair do |mod, act_h|

        $log.debug("1: #{mod} => #{act_h}")

        catch :invocation_found do

          act_h.each_pair do |act_sym, act_path|

            act_path = act_path.chop if act_path.last.eql? '/'
            url = url.chop if (url.last.eql? '/') #let us not let trailing /'s effect anything.
            $log.debug("2: #{act_sym} => #{act_path}")

            if act_path.eql? url

              invocation_found = true
              $log.debug('inv found 1')

            elsif act_path =~ /\{\w+\}/
              id = parse_id(act_path, url)
              if id
                invocation_found = true
                $log.debug('inv found #{id}')
              end
            end

            if invocation_found

              action = act_sym
              module_ = mod
              $log.debug('Invocation found!!')
              throw :invocation_found
            end
          end
        end

        if invocation_found

          $log.debug('Invocation found!!')
          args_hash = {action: action, id: id, params: params}
          return module_.send(:main_fetch, args_hash)
        end
      end

      $log.info("No invocation found for URL #{url}")
      return nil
    end

    private

    #This method will need to be made recursive if the day comes that we have multiple ids in a url.
    def self.parse_id(url_id_template, url_with_id)
      id = nil
      if url_id_template =~ /\{(\w+)\}/
        path_part = "{#{$1}}"
        a = url_id_template.split(path_part)
        first = a[0]
        second = a[1].to_s #nil goes to ""
        if (url_with_id.start_with? first) && (url_with_id.end_with? second)
          id = url_with_id.sub(first, '').sub(second, '')
        end
      end
      id
    end
  end
end

module Gov
  module Vha
    module Isaac
      module Rest
        module Api
          module Exceptions
            class RestExceptionResponse
              include BootstrapNotifier
              def flash_error
                $log.warn("Flashing the error #{self.conciseMessage}")
                flash_alert(message: self.conciseMessage)
              end
            end
          end
        end
      end
    end
  end
end

module CommonRestCallbacks
  def clear_lambda
    -> do
      CommonRest.clear_cache(rest_module: self)
    end
  end
end
=begin
load './lib/isaac_rest/common_rest.rb'
CommonRestBase::RestBase.invoke(url: "http://localhost:8180/rest/1/concept/chronology/cc0b2455-f546-48fa-90e8-e214cc8478d6")
CommonRestBase::RestBase.invoke(url: "http://localhost:8180/rest/1/concept//chronology//cc0b2455-f546-48fa-90e8-e214cc8478d6")
CommonRestBase::RestBase.invoke(url: "rest/1/concept/chronology/cc0b2455-f546-48fa-90e8-e214cc8478d6")
CommonRestBase::RestBase.invoke(url: "http://localhost:8180/rest/1/id/types")
CommonRestBase::RestBase.invoke(url: "rest/1/id/types")
CommonRestBase::RestBase.invoke(url: "http://localhost:8180/rest/1/system/enumeration/restDynamicSememeDataType")
CommonRestBase::RestBase.invoke(url: "rest/1/system/enumeration/restDynamicSememeDataType")
CommonRestBase::RestBase.invoke(url: "rest/1/system/enumeration/restDynamicSememeDataType?expand=children&stated=true")
#above doesn't take parameters but it should still invoke
CommonRestBase::RestBase.invoke(url: "http://localhost:8180/rest/1/id/translate/406e872b-2e19-5f5e-a71d-e4e4b2c68fe5?outputType=nid")
CommonRestBase::RestBase.invoke(url: "rest/1/id/translate/406e872b-2e19-5f5e-a71d-e4e4b2c68fe5?outputType=nid")
CommonRestBase::RestBase.invoke(url: "http://localhost:8180/rest/1/id/translate/406e872b-2e19-5f5e-a71d-e4e4b2c68fe5?outputType=sctid") #this will fail
CommonRestBase::RestBase.invoke(url: "rest/1/id/translate/406e872b-2e19-5f5e-a71d-e4e4b2c68fe5?outputType=sctid") #this will fail
CommonRestBase::RestBase.invoke(url: "rest/1/concept/version/5/")
CommonRestBase::RestBase.invoke(url: "/rest/1/concept/version/5/")
CommonRestBase::RestBase.invoke(url: "rest/1/concept/version/5")
CommonRestBase::RestBase.invoke(url: "rest/1/concept/version/67?expand=children&stated=true")
CommonRestBase::RestBase.invoke(url: "rest/1/not/freacking/there") #this obviously fails
CommonRestBase::RestBase.invoke(url: "rest/1/taxonomy/version?id=cc0b2455-f546-48fa-90e8-e214cc8478d6&expand=chronology")

CommonRestBase::RestBase.invoke(url: "rest/1/search/descriptions?descriptionType=fsn&query=heart")
CommonRestBase::RestBase.invoke(url: "rest/1/search/descriptions?descriptionType=fsn&query=failure&limit=20")
CommonRestBase::RestBase.invoke(url: "rest/1/search/prefix?query=failure&limit=20")


CommonRestBase::RestBase.invoke(url: "rest/1/logicGraph/version/406e872b-2e19-5f5e-a71d-e4e4b2c68fe5")
CommonRestBase::RestBase.invoke(url: "rest/1/logicGraph/chronology/406e872b-2e19-5f5e-a71d-e4e4b2c68fe5")
CommonRestBase::RestBase.invoke(url: "rest/1/sememe/version/309/?expand=nestedSememes")
CommonRestBase::RestBase.invoke(url: "rest/1/sememe/chronology/309")

CommonRest.clear_cache(rest_module: :foo)
CommonRest.clear_cache(rest_module: ConceptRest)
CommonRest.clear_cache(rest_module: CoordinateRest)
CommonRest.clear_cache(rest_module: IdAPIsRest)

CommonRest.clear_cache(rest_module: LogicGraphRest)
CommonRest.clear_cache(rest_module: SearchApiActions)
CommonRest.clear_cache(rest_module: SememeRest)
CommonRest.clear_cache(rest_module: SystemApis)
CommonRest.clear_cache(rest_module: TaxonomyRest)

a = LogicGraphRest::get_graph(action: LogicGraphRestActions::ACTION_CHRONOLOGY,uuid_or_id: LogicGraphRest::TEST_UUID)
a = LogicGraphRest::get_graph(action: LogicGraphRestActions::ACTION_CHRONOLOGY,uuid_or_id: LogicGraphRest::TEST_UUID)
CommonRest.clear_cache(rest_module: LogicGraphRest)
a = LogicGraphRest::get_graph(action: LogicGraphRestActions::ACTION_CHRONOLOGY,uuid_or_id: LogicGraphRest::TEST_UUID)
c = SystemApis::get_system_api(action: SystemApiActions::ACTION_SEMEME_TYPE)
i = SystemApis::get_system_api(action: SystemApiActions::ACTION_SYSTEM_INFO)
CommonRest.clear_cache(rest_module: SystemApis)

=end

