class EtsDashboardController < ApplicationController
  def dashboard
    $log.debug "Index page has been loaded!"
    $log.warn "Index page has been loaded! This could be bad!"
  end
end
