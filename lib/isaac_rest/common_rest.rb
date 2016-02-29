require './lib/ets_common/util/helpers'
require './lib/isaac_rest/ennunciate/isaac-rest.rb'
require 'uri'

module CommonRest
  include ETSUtilities

  UnexpectedResponse = Struct.new(:body, :status) do end

  CONNECTION = Faraday.new do |faraday|
    faraday.request :url_encoded # form-encode POST params
    faraday.use Faraday::Response::Logger, $log
    faraday.headers['Accept'] = 'application/json'
    #faraday.use Faraday::Middleware::ParseJson
    faraday.adapter :net_http # make requests with Net::HTTP
    #faraday.request  :basic_auth, @urls[:user], @urls[:password]
  end

  def uuid_check(uuid:)
    if uuid.nil?
      $log.error('The UUID cannot be nil!  Please esure the caller provides a UUID.')
      raise ArgumentError.new('The UUID cannot be nil!!')
    end
  end

  def rest_fetch(url_string:, params:, raw_url:)
    cache_lookup = {url_string => params}
    unless $rest_cache[cache_lookup].nil?
      $log.info('Using a cached result!  No rest fetch will occur!')
      $log.info("Cache key: #{cache_lookup}")
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
      if (response.status.eql?(200))
        $rest_cache[cache_lookup] = response.body
        return response.body
      end
      $log.warn("Invalid JSON returned from ISAAC rest. URL is #{url_string}")
      $log.warn('Result is ' + response.body)
      $log.warn('Status is ' + response.status.to_s)
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
      raise NotImplementedError.new('You need to implement me in your base class!')
    end

    #see https://github.com/stoicflame/enunciate/
    def enunciate_json(json)
      clazz = get_rest_class

      if (clazz.eql?(JSON) || json.class.eql?(CommonRest::UnexpectedResponse))
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


    def self.register_rest(rest_module:, rest_actions:)
      @@rest_modules ||= {}
      paths = {}
      unless (@@rest_modules.has_key? rest_module)
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
    #{ConceptRest=>{:chronology=>"http://localhost:8180/rest/1/concept/chronology/{id}", :descriptions=>"http://localhost:8180/rest/1/concept/descriptions/{id}", :version=>"http://localhost:8180/rest/1/concept/version/{id}"}}

    def self.invoke(url:)
      $log.debug('invoke')
      isaac_root_url = $PROPS['ENDPOINT.isaac_root']
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
        url.gsub!('//', '^').gsub!(/:\^/,'://').gsub!('^','/')
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
            if (act_path.eql? url)
              invocation_found = true
              $log.debug('inv found 1')
            elsif (act_path.include? '{id}')
              id = parse_id(act_path, url)
              if (id)
                invocation_found = true
                $log.debug('inv found 2 (id)')
              end
            end
            if invocation_found
              action = act_sym
              module_ = mod
              $log.debug('throw happening')
              throw :invocation_found
            end
          end
        end
        if(invocation_found)
          $log.debug('Invocation found!!')
          args_hash = {action: action, id: id, params: params}
          return module_.send(:main_fetch, args_hash )
        end
      end
      $log.info("No invocation found for URL #{url}")
      return nil
    end

    private

    def self.parse_id(url_id_template, url_with_id)
      id = nil
      if (url_id_template =~ /\{id\}/)
        a = url_id_template.split('{id}')
        first = a[0]
        second = a[1].to_s #nil goes to ""
        if ((url_with_id.start_with? first) && (url_with_id.end_with? second))
          id = url_with_id.sub(first, '').sub(second, '')
        end
      end
      id
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
=end
