#these are the the users in test
module RolesTest
  def self.user_roles(user:, password:)
    users_development = [{'user' => 'devtest', 'pwd' => 'devtest', 'token' => 'whatever1', 'roles' => [::Roles::ADMINISTRATOR.to_s, ::Roles::EDITOR.to_s, ::Roles::READ_ONLY.to_s]},
                         {'user' => 'cris', 'pwd' => 'cris', 'token' => 'whatever2', 'roles' => [::Roles::APPROVER.to_s, ::Roles::REVIEWER.to_s]},
                         {'user' => 'greg', 'pwd' => 'greg', 'token' => 'whatever3', 'roles' => [::Roles::SUPER_USER.to_s, ::Roles::EDITOR.to_s]},
                         {'user' => 'read', 'pwd' => 'read', 'token' => 'whatever4', 'roles' => [::Roles::READ_ONLY.to_s]}]
    users_development.each do |user_info|
      if user_info['user'].eql? user
        if user_info['pwd'].eql? password
          return user_info
        end
      end
    end
    {}
  end
end
