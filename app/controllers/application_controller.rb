require './lib/rails_common/util/controller_helpers'
require 'faraday'
require 'openssl'
require './lib/rails_common/roles/ssoi'

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

class ApplicationController < ActionController::Base
  include CommonController
  include SSOI
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :ensure_rest_version
  before_action :ensure_roles
  before_action :set_render_menu, :setup_routes, :setup_constants
  attr_reader :ssoi # a boolean if we have ssoi headers
  alias ssoi? ssoi

  rescue_from Exception, :with => :internal_error

  def set_render_menu
    @set_render_menu = true
  end

  def internal_error(e)
    $log.error(e.message)
    $log.error request.fullpath
    $log.error(e.backtrace.join("\n"))
    raise e
  end

  #REST_API_VERSIONS
  def ensure_rest_version
    if ISAAC_ROOT.empty?
      $log.warn('The isaac rest service is not available. All attempts to connect to possible ISAAC Rest Services Failed in the application initializer code (01_komet_init.rb)')
      render 'errors/isaac_rest_init_error'
      return
    end

    begin
      response = SystemApis::get_system_api(action: SystemApiActions::ACTION_SYSTEM_INFO)
      unless response.is_a? CommonRest::UnexpectedResponse
        @@invalid_rest_server ||= (response.supportedAPIVersions.map do |e|
          e.split('.').slice(0, 2).join('.')
        end & REST_API_VERSIONS.map(&:to_s)).empty? # '&' is intersection operator for arrays
      else
        @unexpected_message = response.body
      end
    rescue Faraday::ConnectionFailed => ex
      @unexpected_message = ex.message
    end
    if (@unexpected_message)
      $log.warn("The isaac rest server is not available.  Message is: #{@unexpected_message}")
      render 'errors/isaac_initializing'
      return
    end
    if (@@invalid_rest_server)
      versions = SystemApis::get_system_api(action: SystemApiActions::ACTION_SYSTEM_INFO).supportedAPIVersions
      render :file => (trinidad? ? 'public/invalid_issac_rest.html' : "#{Rails.root}/../invalid_issac_rest.html")
      $log.fatal("The isaac rest server this instance of Komet is pointed to is invalid!")
      $log.fatal("The isaac rest server version list is: #{versions}")
      $log.fatal("My supported version list is: #{REST_API_VERSIONS}")
      $log.fatal("Komet will not function until this is resolved!")
      return
    end
  end

  def ensure_roles
    $log.debug("Ensuring roles for #{request.fullpath}")
    user_name = ssoi_headers
    @ssoi = !user_name.to_s.strip.empty? #we are using ssoi
    $log.debug("SSOI headers present? " + ssoi?.to_s + " ssoi user is #{user_name}")
    roles = session[Roles::SESSION_ROLES_ROOT][Roles::SESSION_USER_ROLES]
    user = session[Roles::SESSION_ROLES_ROOT][Roles::SESSION_USER]
    password = session[Roles::SESSION_ROLES_ROOT][Roles::SESSION_PASSWORD] unless ssoi
    #overwrite session values if this data comes from login form
    if(params['komet_username'] && params['komet_password'] && !ssoi)
      #we are coming from the login page
      user = params['komet_username']
      password = params['komet_password']
      session[Roles::SESSION_ROLES_ROOT][Roles::SESSION_LAST_ROLE_CHECK] = nil
    end
    session[Roles::SESSION_ROLES_ROOT][Roles::SESSION_LAST_ROLE_CHECK] =  100.years.ago if session[Roles::SESSION_ROLES_ROOT][Roles::SESSION_LAST_ROLE_CHECK].nil?
    time_for_recheck = (Time.now - session[Roles::SESSION_ROLES_ROOT][Roles::SESSION_LAST_ROLE_CHECK]) > $PROPS['KOMET.roles_recheck_in_seconds'].to_i
    if (session[Roles::SESSION_ROLES_ROOT][Roles::SESSION_LAST_ROLE_CHECK].nil? || time_for_recheck)
      $log.debug("Refetching the roles")
      if (!ssoi? && (!FileTest.exists?("#{Rails.root}/config/props/prisme.properties") || $PROPS['PRISME.prisme_roles_url'].nil?))
        load './lib/roles_test/roles.rb'
        roles = RolesTest::user_roles(user: user, password: password)
        session[Roles::SESSION_ROLES_ROOT][Roles::SESSION_LAST_ROLE_CHECK] = Time.now
      else
        $log.debug("Getting the roles from PRISME")
        #todo
        #nil check on prop below needed, error log will never be seen
        #wrap in begin end block
        begin
          roles_url = ssoi ? URI($PROPS['PRISME.prisme_roles_ssoi_url']) : URI($PROPS['PRISME.prisme_roles_url'])
        rescue
          $log.error("The roles url is not set!  Was this instance of Komet deployed from Prisme?  If not you must manually set the property.  See ./config/props/prisme.properties")
        end
        conn = get_rest_connection(roles_url.base_url)
        response = nil
        error = false
        begin
          user_params  = {} #id: user, password: password.to_s
          user_params[:id] = user
          user_params[:password] = password.to_s unless ssoi
          user_params[:format] = 'json'
          roles_body = conn.get(roles_url.path, user_params).body
          $log.debug("Roles body from prisme is: #{roles_body}")
          response = JSON.parse roles_body
        rescue => ex
          $log.error("Komet could not communicate with PRISME at URL #{roles_url}")
          $log.error("Error message is #{ex.message}")
          error = true
          roles = nil
        end
        unless error
          session[Roles::SESSION_ROLES_ROOT][Roles::SESSION_LAST_ROLE_CHECK] = Time.now
          roles = []
          response.each do |r|
            roles << r['name']
          end
        end
      end
      if (roles)
        session[Roles::SESSION_ROLES_ROOT][Roles::SESSION_USER] = user
        session[Roles::SESSION_ROLES_ROOT][Roles::SESSION_USER_ROLES] = roles
        session[Roles::SESSION_ROLES_ROOT][Roles::SESSION_PASSWORD] = password unless ssoi
      else
        session[Roles::SESSION_ROLES_ROOT][Roles::SESSION_USER] = user
        session[Roles::SESSION_ROLES_ROOT][Roles::SESSION_USER_ROLES] = nil
        session[Roles::SESSION_ROLES_ROOT][Roles::SESSION_PASSWORD] = nil unless ssoi
      end
    end
    $log.debug("The roles for user #{session[Roles::SESSION_ROLES_ROOT][Roles::SESSION_USER]} are #{roles}")
    roles
  end

  def setup_constants

    if $isaac_metadata_auxiliary.nil?

      constants_file = './config/generated/yaml/IsaacMetadataAuxiliary.yaml'
      prefix = File.basename(constants_file).split('.').first.to_sym
      json = YAML.load_file constants_file
      translated_hash = add_translations(json)
      $isaac_metadata_auxiliary = translated_hash
      $isaac_metadata_auxiliary.freeze
    end

    gon.IsaacMetadataAuxiliary = $isaac_metadata_auxiliary
  end

  private
  def get_rest_connection(url, header = 'application/json')
    conn = Faraday.new(url: url) do |faraday|
      faraday.request :url_encoded # form-encode POST params
      faraday.use Faraday::Response::Logger, $log
      faraday.headers['Accept'] = header
      faraday.adapter :net_http # make requests with Net::HTTP
      #faraday.basic_auth(props[PrismeService::NEXUS_USER], props[PrismeService::NEXUS_PWD])
    end
    conn
  end

  def add_translations(json)
    translated_hash = json.deep_dup
    json.keys.each do |k|
      translated_array = []
      json[k]['uuids'].each do |uuid|
        translation = JSON.parse IdAPIsRest::get_id(action: IdAPIsRestActions::ACTION_TRANSLATE, uuid_or_id: uuid, additional_req_params: {"outputType" => "conceptSequence"}).to_json
        translated_array << {uuid: uuid, translation: translation}
      end
      translated_hash[k]['uuids'] = translated_array
    end
    #json_to_yaml_file(translated_hash,'reema')
    translated_hash
  end

end
