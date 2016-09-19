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

  skip_before_action :ensure_roles, only: [:login]
  skip_after_action :verify_authorized
  skip_before_action :read_only?

  def login
    user_name = ssoi_headers
    @ssoi = !user_name.to_s.strip.empty? #we are using ssoi
    if ssoi?
      ensure_roles
      roles = session[Roles::SESSION_ROLES_ROOT][Roles::SESSION_USER_ROLES]
      $log.debug("SSOI has the following roles: #{roles}")
      unless roles.nil? || roles.empty?
        redirect_to komet_dashboard_dashboard_url
        return
      end
    end
    $log.debug('Rendering the standard login page')
  end

  def authenticate
    roles = nil

    if session[Roles::SESSION_ROLES_ROOT]
      roles = session[Roles::SESSION_ROLES_ROOT][Roles::SESSION_USER_ROLES]
    end

    if roles.nil? || roles.empty?
      #not authenticated - redirect to the naughty page
      flash[:error] = 'Invalid username or password.'
      redirect_to proxify(root_path)
    else
      redirect_to komet_dashboard_dashboard_url
    end
  end

  def logout
    session.delete(Roles::SESSION_ROLES_ROOT)
    flash[:notice] = 'You have been logged out.'
    logout_url_string = ssoi? ? PrismeConfigConcern.logout_link : root_url
    redirect_to logout_url_string
  end
end
