namespace :isaac do
  # set ISAAC_PATH=<path to isaac workspace>
  local_isaac = ENV['ISAAC_PATH']

  desc 'Build local isaac rest project'
  task :build_isaac_rest do |task|
    if local_isaac
      sh "cd #{local_isaac}/ISAAC-rest && git pull"
      sh "cd #{local_isaac}/ISAAC-rest && mvn clean install"
    else
      puts 'set ISAAC_PATH to your local isaac workspace in this shell before executing the rake task'
    end
  end

  task :build => :build_isaac_rest
  task :b => :build_isaac_rest

end
