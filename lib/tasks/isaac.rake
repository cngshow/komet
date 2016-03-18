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

  desc 'Build all isaac projects'
  task :build_all do |task|
    if local_isaac
      Dir.chdir(local_isaac)
      files = Dir.glob('*').map do |f| local_isaac + java.io.File.separator + f end
      #puts "Files is: #{files} for #{local_isaac}"
      built = []
      files.each do |directory|
       # puts "Examining #{directory}"
        if (File.directory?(directory) && File.exists?(directory + java.io.File.separator + 'pom.xml'))
        #  puts "here"
          sh "cd #{directory} && git pull"
          sh "cd #{directory} && mvn clean install"
          built << directory
        end
      end
      puts "Processed the following directories:"
      puts built.inspect.to_s
    else
      puts 'set ISAAC_PATH to your local isaac workspace in this shell before executing the rake task'
    end
  end

  desc 'Build local isaac rest project'
  task :build_r => :build_isaac_rest
  desc 'Build local isaac rest project'
  task :br => :build_isaac_rest

  desc 'Build local isaac rest project'
  task :b => :build_all

end
