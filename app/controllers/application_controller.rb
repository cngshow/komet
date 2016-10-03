require './lib/rails_common/util/controller_helpers'
require 'faraday'
require 'openssl'
require './lib/rails_common/roles/ssoi'
require './lib/rails_common/roles/user_session'
require './lib/rails_common/util/servlet_support'

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

class ApplicationController < ActionController::Base
  include CommonController
  include ApplicationHelper
  include Pundit
  include SSOI
  include UserSession
  include ServletSupport

  CACHE_TYPE_ALL = :all_caches
  CACHE_TYPE_TAXONOMY = :taxonomy_caches
  CACHE_TYPE_SYSTEM = :system_caches

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  prepend_before_action :add_pundit_methods
  after_action :verify_authorized
  before_action :ensure_rest_version
  before_action :ensure_roles
  before_action :read_only? # must be after ensure_roles
  # todo tried testing with reviewer? and could not get to the login page

  before_action :set_render_menu, :setup_routes, :setup_constants
  attr_reader :ssoi # a boolean if we have ssoi headers
  alias ssoi? ssoi

  rescue_from Exception, :with => :internal_error
  rescue_from Pundit::NotAuthorizedError, Pundit::AuthorizationNotPerformedError, :with => :pundit_error

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
      $log.fatal('The isaac rest server this instance of Komet is pointed to is invalid!')
      $log.fatal("The isaac rest server version list is: #{versions}")
      $log.fatal("My supported version list is: #{REST_API_VERSIONS}")
      $log.fatal('Komet will not function until this is resolved!')
    end
  end

  def ensure_roles
    # read the request headers to see if we are SSOI
    $log.debug("Ensuring roles for #{request.fullpath}")
    user_name = ssoi_headers
    @ssoi = !user_name.to_s.strip.empty? #we are using ssoi

    # pull the current login creds from the session
    user_login = user_session(UserSession::LOGIN)
    user_pwd = ssoi? ? nil : user_session(UserSession::PWD)

    #overwrite session values if this data comes from login form and we are not SSOI
    if params['komet_username'] && params['komet_password'] && !ssoi?
      user_login = params['komet_username']
      user_pwd = params['komet_password']

      # null out the last role check so we will refresh the roles with this login
      user_session(UserSession::LAST_ROLE_CHECK, nil)
    end

    # determine if we need to refresh the user's roles
    user_session(UserSession::LAST_ROLE_CHECK, 1.year.ago) if user_session(UserSession::LAST_ROLE_CHECK).nil?
    refresh_roles = (Time.now - user_session(UserSession::LAST_ROLE_CHECK)) > $PROPS['KOMET.roles_recheck_in_seconds'].to_i

    if refresh_roles
      user_info = nil
      $log.debug('Refreshing the roles')

      if !ssoi? && (!FileTest.exists?("#{Rails.root}/config/props/prisme.properties") || $PROPS['PRISME.prisme_roles_url'].nil?)
        load './lib/roles_test/roles.rb'
        user_info = RolesTest::user_roles(user: user_login, password: user_pwd)
      else
        begin
          # pull the prisme roles url from the properties file
          roles_url = ssoi? ? $PROPS['PRISME.prisme_roles_ssoi_url'] : $PROPS['PRISME.prisme_roles_url']

          if roles_url && URI.valid_url?(url_string: roles_url)
            roles_url = URI(roles_url)
            conn = CommonController.get_rest_connection(roles_url.base_url)
            user_params = {} #id: user, password: password.to_s
            user_params[:id] = user_login
            user_params[:password] = user_pwd.to_s unless ssoi
            user_params[:format] = 'json'
            roles_body = conn.get(roles_url.path, user_params).body
            user_info = JSON.parse(roles_body)
          else
            $log.error('The roles url is not set!  Was this instance of Komet deployed from Prisme?  If not you must manually set the property.  See ./config/props/prisme.properties')
          end
        rescue => ex
          $log.error("KOMET could not communicate with PRISME at URL #{roles_url}")
          $log.error("Error message is #{ex.message}")
        end
      end
      if user_info
        user_session(UserSession::LAST_ROLE_CHECK, Time.now)
        user_session(UserSession::LOGIN, user_login)
        user_session(UserSession::ROLES, user_info['roles'])
        user_session(UserSession::TOKEN, user_info['token'])
        user_session(UserSession::PWD, ssoi ? nil : user_pwd)
      else
        user_session(UserSession::LOGIN, user_login)
        user_session(UserSession::ROLES, nil)
        user_session(UserSession::TOKEN, nil)
        user_session(UserSession::PWD, ssoi? ? nil : user_pwd)
        user_session(UserSession::LAST_ROLE_CHECK, nil)
      end
    end
    $log.debug("The roles for user #{user_session(UserSession::LOGIN)} are #{user_session(UserSession::ROLES)}")
    user_session(UserSession::ROLES)
  end

  def self.parse_isaac_metadata_auxiliary
    if $isaac_metadata_auxiliary.nil?
      constants_file = './config/generated/yaml/IsaacMetadataAuxiliary.yaml'
      prefix = File.basename(constants_file).split('.').first.to_sym
      json = YAML.load_file constants_file
      translated_hash = add_translations(json)
      $isaac_metadata_auxiliary = translated_hash
      $isaac_metadata_auxiliary.freeze
    end
  end

  def setup_constants
    ApplicationController.parse_isaac_metadata_auxiliary
    gon.IsaacMetadataAuxiliary = $isaac_metadata_auxiliary
  end

  def pundit_user
    if user_session_defined?
      {user: user_session(UserSession::LOGIN),
       roles: user_session(UserSession::ROLES),
       token: user_session(UserSession::TOKEN)}
    else
      {user: nil, roles: [], token: 'Not Authorized'}
    end
  end

  #dynamically add authorization methods
  def add_pundit_methods
    PunditDynamicRoles::add_controller_methods self
  end

  ##
  # clear_rest_caches - Clear all relevant REST caches
  # @param [String] cache_type - An ApplicationController constant representing the types of caches to clear:
  #                               CACHE_TYPE_TAXONOMY - (default) clears all taxonomy related caches, anything that would be displayed in the GUI
  #                               CACHE_TYPE_SYSTEM - clears all caches that deal with internal system data (ie: metadata, coordinate tokens, ect.). Should very rarely be used
  #                               CACHE_TYPE_ALL - clears all caches. Should very rarely be used
  def clear_rest_caches(cache_type: CACHE_TYPE_TAXONOMY)

    if cache_type == CACHE_TYPE_TAXONOMY || cache_type == CACHE_TYPE_ALL

      CommonRest.clear_cache(rest_module: CommentApis)
      CommonRest.clear_cache(rest_module: ConceptRest)
      CommonRest.clear_cache(rest_module: IdAPIsRest)
      CommonRest.clear_cache(rest_module: LogicGraphRest)
      CommonRest.clear_cache(rest_module: MappingApis)
      CommonRest.clear_cache(rest_module: SearchApis)
      CommonRest.clear_cache(rest_module: SememeRest)
      CommonRest.clear_cache(rest_module: TaxonomyRest)

    elsif cache_type == CACHE_TYPE_SYSTEM || cache_type == CACHE_TYPE_ALL

      CommonRest.clear_cache(rest_module: CoordinateRest)
      CommonRest.clear_cache(rest_module: SystemApis)
    end
  end

  private
  def self.add_translations(json)
    translated_hash = json.deep_dup
    json.keys.each do |k|
      translated_array = []
      json[k]['uuids'].each do |uuid|
        translation = JSON.parse IdAPIsRest::get_id(action: IdAPIsRestActions::ACTION_TRANSLATE, uuid_or_id: uuid, additional_req_params: {'outputType' => 'conceptSequence'}).to_json
        translated_array << {uuid: uuid, translation: translation}
      end
      translated_hash[k]['uuids'] = translated_array
    end
    #json_to_yaml_file(translated_hash,'reema')
    translated_hash
  end

end
