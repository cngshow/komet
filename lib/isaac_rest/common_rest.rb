require './lib/ets_common/util/helpers'
require './lib/isaac_rest/ennunciate/isaac-rest.rb'
require './lib/ets_common/util/helpers'

module CommonRest
  include ETSUtilities

  UnexpectedResponse = Struct.new(:body, :status) do end

  CONNECTION = Faraday.new() do |faraday|
    faraday.request :url_encoded # form-encode POST params
    faraday.use Faraday::Response::Logger, $log
    faraday.headers['Accept'] = 'application/json'
    #faraday.use Faraday::Middleware::ParseJson
    faraday.adapter :net_http # make requests with Net::HTTP
    #faraday.request  :basic_auth, @urls[:user], @urls[:password]
  end

  def uuid_check(uuid:)
    if (uuid.nil?)
      $log.error("The UUID cannot be nil!  Please esure the caller provides a UUID.")
      raise ArgumentError.new("The UUID cannot be nil!!")
    end
  end

  def rest_fetch(url_string:, params:, raw_url:)
    cache_lookup = {url_string => params}
    unless $rest_cache[cache_lookup].nil?
      $log.info("Using a cached result!  No rest fetch will occur!")
      $log.info("Cache key: " + cache_lookup.to_s)
      json = $rest_cache[cache_lookup]
      json_to_yaml_file(json, url_to_path_string(raw_url))
      return json.deep_dup
    end

    response = CONNECTION.get do |req|
      req.url url_string
      req.params = params
    end
    json = nil
    begin
      json = JSON.parse response.body
    rescue JSON::ParserError => ex
      if(response.status.eql?(200))
        $rest_cache[cache_lookup] = response.body
            return response.body
      end
      $log.warn("Invalid JSON returned from ISAAC rest. URL is #{url_string}")
      $log.warn("Result is " + response.body)
      $log.warn("Status is " + response.status.to_s)
      return UnexpectedResponse.new(response.body, response.status)
    end
    json.freeze
    json_to_yaml_file(json, url_to_path_string(raw_url))
    $rest_cache[cache_lookup] = json
    json.deep_dup
  end
end

module CommonActionSyms
  PATH_SYM = :path
  CLAZZ_SYM = :clazz
  STARTING_PARAMS_SYM = :starting_params
end

module CommonRestBase
  class RestBase
    include CommonActionSyms
    attr_accessor :params, :action, :action_constants

    def initialize(params:, action:, action_constants:)
      @params = params
      @action = action
      @action_constants = action_constants
    end

    def url
      action_constants.fetch(action).fetch(PATH_SYM)
    end

    def get_params
      r_val = action_constants.fetch(action).fetch(STARTING_PARAMS_SYM).clone
      r_val.merge!(params) unless params.nil?
      r_val
    end

    def get_rest_class
      action_constants.fetch(action).fetch(CLAZZ_SYM)
    end

    def rest_call
      raise NotImplementedError.new("You need to implement me in your base class!")
    end

    #see https://github.com/stoicflame/enunciate/
    def enunciate_json(json)
      clazz = get_rest_class
      if clazz.eql?(JSON)
        return json
      end
      r_val = nil
      if json.is_a? Array
        r_val = []
        json.each do |elem|
          r_val.push(clazz.send(:from_json, elem))
        end
      else
        r_val = clazz.send(:from_json, json)
      end
      r_val
    end
  end
end

#load './lib/isaac_rest/common_rest.rb'