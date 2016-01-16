Rake::TaskManager.record_task_metadata = true
#set GLASSFISH_ROOT=C:\work\ETS\glassfish
#this is also the context root
#set RAILS_RELATIVE_URL_ROOT=/ets_tooling
#domain 1 is the default if is this is unset
#set GLASSFISH_DOMAIN=domain1
#glassfish console:
#http://localhost:4848/

namespace :devops do
  def env(env_var,default)
    ENV[env_var].nil? ? default : ENV[env_var]
  end

  default_war = "ets_tooling.war"
  default_undeploy = default_war.split('.')[0]
  context = env('RAILS_RELATIVE_URL_ROOT','/ets_tooling')
  ENV['RAILS_RELATIVE_URL_ROOT'] = env('RAILS_RELATIVE_URL_ROOT','/ets_tooling')
  ENV['RAILS_ENV'] = env('RAILS_ENV','test')
  domain = env('GLASSFISH_DOMAIN', 'domain1')


  desc "Start up glassfish"
  task :glass_start do |task|
    p task.comment
    Bundler.with_clean_env do
      #until I learn more we will not give glass fish any access to our environment
      sh "#{ENV['GLASSFISH_ROOT']}/glassfish4/bin/asadmin start-domain #{domain}"
    end

  end

  desc "Stop glassfish"
  task :glass_stop do |task|
    p task.comment
    sh "#{ENV['GLASSFISH_ROOT']}/glassfish4/bin/asadmin stop-domain #{domain}"
  end

  desc "Build war file"
  task :build_war do |task|
    p task.comment
    Rake::Task['devops:bundle'].invoke
    Rake::Task['devops:compile_assets'].invoke
    sh "warble"
  end

  desc "Compile assets"
  task :compile_assets do |task|
    p task.comment
    Rake::Task['assets:precompile'].invoke
  end

  desc "Install bundle"
  task :bundle do |task|
    p task.comment
    sh "bundle install"
  end

  desc "Deploy ets tooling rails to glassfish"
  task :deploy do |task|
    p task.comment
    Rake::Task['devops:build_war'].invoke
    sh "#{ENV['GLASSFISH_ROOT']}/glassfish4/bin/asadmin deploy --contextroot #{context} #{default_war}"
  end

  desc "Undeploy ets tooling rails from glassfish"
  task :undeploy do |task|
    puts task.comment
    sh "#{ENV['GLASSFISH_ROOT']}/glassfish4/bin/asadmin undeploy #{default_undeploy}"
  end

end