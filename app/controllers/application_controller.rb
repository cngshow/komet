require './lib/rails_common/util/controller_helpers'
require 'faraday'
require 'openssl'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

class ApplicationController < ActionController::Base
  include CommonController
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :ensure_rest_version
  before_action :ensure_roles

  rescue_from Exception, :with => :internal_error

  def internal_error(e)
    $log.error(e.message)
    $log.error request.fullpath
    $log.error(e.backtrace.join("\n"))
    raise e
  end

  #REST_API_VERSIONS
  def ensure_rest_version
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
    roles = session[Roles::SESSION_USER_ROLES]
    user = session[Roles::SESSION_USER]
    password = session[Roles::SESSION_PASSWORD]
    #overwrite session values if this data comes from login form
    if(params['komet_username'] && params['komet_password'])
      #we are coming from the login page
      user = params['komet_username'] unless params['komet_username'].nil?
      password = params['komet_password'] unless params['komet_password'].nil?
      session[Roles::SESSION_LAST_ROLE_CHECK] = nil
    end
    session[Roles::SESSION_LAST_ROLE_CHECK] =  100.years.ago if session[Roles::SESSION_LAST_ROLE_CHECK].nil?
    time_for_recheck = (Time.now - session[Roles::SESSION_LAST_ROLE_CHECK]) > $PROPS['KOMET.roles_recheck_in_seconds'].to_i
    if (session[Roles::SESSION_LAST_ROLE_CHECK].nil? || time_for_recheck)
      $log.debug("Refetching the roles")
      if (Rails.env.development? && !boolean($PROPS['PRISME.use_prisme']))
        load './lib/roles_test/roles.rb'
        roles = RolesTest::user_roles(user: user, password: password)
        session[Roles::SESSION_LAST_ROLE_CHECK] = Time.now
      else
        $log.debug("Getting the roles from PRISME")
        #todo
        #nil check on prop below needed, error log will never be seen
        #wrap in begin end block
        begin
          roles_url = URI($PROPS['PRISME.prisme_roles_url'])
        rescue
          $log.error("The roles url is not set!  Was this instance of Komet deployed from Prisme?  If not you must manually set the property.  See ./config/props/prisme.properties")
        end
        conn = get_rest_connection(roles_url.base_url)
        response = nil
        error = false
        begin
          response = JSON.parse conn.get(roles_url.path, id: user, password: password.to_s).body
        rescue => ex
          $log.error("Komet could not communicate with PRISME at URL #{roles_url}")
          $log.error("Error message is #{ex.message}")
          error = true
          roles = nil
        end
        unless error
          session[Roles::SESSION_LAST_ROLE_CHECK] = Time.now
          roles = []
          response.each do |r|
            roles << r['name']
          end
        end
      end
      if (roles)
        session[Roles::SESSION_USER] = user
        session[Roles::SESSION_USER_ROLES] = roles
        session[Roles::SESSION_PASSWORD] = password
      else
        session[Roles::SESSION_USER] = user
        session[Roles::SESSION_USER_ROLES] = nil
        session[Roles::SESSION_PASSWORD] = nil
      end
    end
    $log.debug("The roles for user #{session[Roles::SESSION_USER]} are #{roles}")
    roles
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

end
