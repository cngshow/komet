=begin
Copyright Notice

 This is a work of the U.S. Government and is not subject to copyright
 protection in the United States. Foreign copyrights may apply.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
=end


##
# ExternalController -
# handles the login and all resources outside of login
class ExternalController < ApplicationController

  # we cannot skip ensure roles on logout because we need to have @ssoi set to determine the redirect url
  skip_before_action :ensure_roles, only: [:login]
  skip_after_action :verify_authorized
  skip_before_action :read_only?

  def login
    user_name = ssoi_headers
    @ssoi = !user_name.to_s.strip.empty? #we are using ssoi

    # if we are SSOI then pull the ensure the user has roles
    if ssoi?
      ensure_roles

      # redirect to komet dashboard if the user has roles
      if user_session(UserSession::ROLES)
        redirect_to komet_dashboard_dashboard_url
        return
      end
    end
    $log.debug('Rendering the standard login page')
  end

  def authenticate
    if user_session(UserSession::ROLES)
      redirect_to komet_dashboard_dashboard_url
    else
      #not authenticated - redirect to the naughty page
      flash[:error] = 'Invalid username or password.'
      redirect_to root_url
    end
  end

  def logout
    clear_user_session
    clear_user_workflow
    flash[:notice] = 'You have been logged out.'
    logout_url_string = ssoi? ? PrismeConfigConcern.logout_link : root_url
    redirect_to logout_url_string
  end
end
