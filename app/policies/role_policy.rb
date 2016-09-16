class RolePolicy < Struct.new(:user_and_roles, :role)

  def initialize(user_and_roles, role)
    PunditDynamicRoles::add_policy_methods(self,user_and_roles)
  end

end

=begin

in the land of erb:

<% if policy(:role).reviewer? %>

#sample before_actions (see roles.rb in rails_common):
before_action :approver?
before_action :editor?, only: [:edit_concept, :edit_uuid]
before_action :reviewer?, except: [:edit_concept, :edit_uuid]

#a composite role (or based)
before_action :any_approver?

load('./app/policies/role_policy.rb')
=end