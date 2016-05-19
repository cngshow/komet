require './lib/rails_common/util/controller_helpers'

class ApplicationController < ActionController::Base
  include CommonController
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :ensure_rest_version

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
      @@invalid_rest_server ||= (SystemApis::get_system_api(action: SystemApiActions::ACTION_SYSTEM_INFO).supportedAPIVersions.map do |e| e.split('.').slice(0, 2).join('.') end & REST_API_VERSIONS.map(&:to_s)).empty? # '&' is intersection operator for arrays
    rescue CommonRest::UnexpectedResponse, Faraday::ConnectionFailed => ex
      if (ex.is_a? CommonRest::UnexpectedResponse)
        @unexpected_message = ex.body
      else
        @unexpected_message = ex.message
      end
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

end
