#these are the the users in test
module RolesTest
  def self.user_roles(user:, password:)
    users_development = [['devtest', 'devtest',[::Roles::ADMINISTRATOR, ::Roles::EDITOR, ::Roles::READ_ONLY]], ['cris', 'cris', [::Roles::APPROVER, ::Roles::REVIEWER]], ['greg', 'greg', [::Roles::SUPER_USER, ::Roles::EDITOR]]]
    users_development.each do |user_role|
      if user_role.first.eql? user
        return user_role.last if user_role[1].eql? password
      end
    end
    nil
  end
end
