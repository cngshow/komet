class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  rescue_from Exception, :with => :internal_error

  def internal_error(e)
    $log.error(e.message) 
    $log.error request.fullpath
    $log.error(e.backtrace.join("\n"))
    raise e
  end

end
