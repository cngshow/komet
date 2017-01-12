# this controller was created because you cannot route to the application controller so we needed a controller
# to handle the mixed in method in bootstrap_notifier.rb that handles the setting and displaying of flash messages
# via the bootstrap-notify-growl gem
class FlashNotifierController < ApplicationController

  # remove all filters to improve performance as this is only called for displaying flash messages
  all_filters = self._process_action_callbacks.map(&:filter)
  all_filters.each {|sym| skip_action_callback(sym)}
  before_filter :ensure_roles, only: [:roles]
  $log.trace(all_filters)

  def roles
    $log.trace("#{pundit_user}")
    render json: pundit_user[:roles]
  end

end
