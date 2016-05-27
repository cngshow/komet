require './lib/rails_common/util/controller_helpers'

class ApplicationController < ActionController::Base
  include CommonController
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :ensure_rest_version
  before_action :ensure_roles, except: [:logout]

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
    roles = session[Roles::SESSION_USER_ROLES]
    user = session[Roles::SESSION_USER]
    password = session[Roles::SESSION_PASSWORD]
    session[Roles::SESSION_LAST_ROLE_CHECK] =  100.years.ago if session[Roles::SESSION_LAST_ROLE_CHECK].nil?
    time_for_recheck = (Time.now - session[Roles::SESSION_LAST_ROLE_CHECK]) > $PROPS['KOMET.roles_recheck_in_seconds'].to_i
    if (session[Roles::SESSION_LAST_ROLE_CHECK].nil? || time_for_recheck)
      #refetch roles
      if (Rails.env.development? && !boolean($PROPS['PRISME.use_prisme_root']))
        load './lib/roles_test/roles.rb'
        user = params['komet_username'] unless params['komet_username'].nil?
        password = params['komet_password'] unless params['komet_password'].nil?
        roles = RolesTest::user_roles(user: user, password: password)
        session[Roles::SESSION_LAST_ROLE_CHECK] = Time.now
      else
        #get roles from prisme
        puts "Hi"
        session[Roles::SESSION_LAST_ROLE_CHECK] = Time.now
      end
      if (roles)
        session[Roles::SESSION_USER] = user
        session[Roles::SESSION_USER_ROLES] = roles
        session[Roles::SESSION_PASSWORD] = password
      end
    end
    roles
  end
end
