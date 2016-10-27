# this controller was created because you cannot route to the application controller so we needed a controller
# to handle the mixed in method in bootstrap_notifier.rb that handles the setting and displaying of flash messages
# via the bootstrap-notify-growl gem
class FlashNotifierController < ApplicationController

  # remove all filters to improve performance as this is only called for displaying flash messages
  all_filters = self._process_action_callbacks.map(&:filter)
  all_filters.each {|sym| skip_action_callback(sym)}
  $log.fatal(all_filters)

  # this is called from application.js when ajax calls are completed to flash messages
  def flash_notifications
    $log.fatal("calling flash notifications")
    render json: show_flash
  end

end
