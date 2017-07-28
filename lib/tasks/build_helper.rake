require 'fileutils'

namespace :devops do
  ENV['NODE_ENV'] = Rails.env
  cleanup = 'Cleanup react on rails'
  setup = 'Set up react on rails'
  desc cleanup
  task :cleanup_react do
    $react_build = true
    w_d = './app/assets/webpack/'
    n_m = './client/node_modules'
    begin
      FileUtils.remove_dir(w_d)
      puts "#{w_d} removed."
    rescue => ex
      puts "Failed to remove #{w_d}, error: #{$!}"
    end
    begin
      FileUtils.remove_dir(n_m)
      puts "#{n_m} removed."
    rescue => ex
      puts "Failed to remove #{n_m}, error: #{$!}"
    end
  end

  desc setup
  task :set_up_react do
    Rake::Task['devops:cleanup_react'].invoke
    Dir.chdir('./client') do
      sh 'yarn install'
      Rake::Task['react_on_rails:locale'].invoke
    end

    if (Rails.env.development?)
      puts 'Running: yarn run build:development'
      Dir.chdir('./client') do
        sh 'yarn run build:development'
      end
      puts 'Done..'
    else
      Dir.chdir('./client') do
        puts 'Running: yarn run build:production'
        sh 'yarn run build:production'
        puts 'Done..'
      end
      #unix land, we assume we are on the build server
      #rake react_on_rails:assets:webpack
 #     puts 'Running: react_on_rails:assets:webpack'
#      Rake::Task['react_on_rails:assets:webpack'].invoke
     # puts 'Done..'
    end
  end

  desc cleanup
  task :c => :cleanup_react

  desc setup
  task :s => :set_up_react

end
