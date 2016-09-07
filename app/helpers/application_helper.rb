module ApplicationHelper
  def komet_user
    user = 'unknown'
    user = session[Roles::SESSION_ROLES_ROOT][Roles::SESSION_USER] if session.has_key?(Roles::SESSION_ROLES_ROOT)
    user
  end
end
