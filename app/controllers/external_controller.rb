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

  skip_before_action :ensure_roles, only: [:logout, :login]

  def login
    #render external#login
  end

  def authenticate
    roles = session[Roles::SESSION_USER_ROLES]
    unless(roles.nil? || roles.empty?)
      redirect_to komet_dashboard_dashboard_url
    else
      #not authenticated - redirect to the naughty page
      flash[:error] = "Invalid username or password."
      redirect_to root_url
    end
  end

  def logout
    roles = session[Roles::SESSION_USER_ROLES]
    session.delete(:current_user)
    session.delete(:current_user_roles)
    session.delete(:current_password)
    flash[:notice] = "You have been logged out."
    redirect_to root_url
  end



end