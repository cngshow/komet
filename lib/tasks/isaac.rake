namespace :isaac do

  def require_all(dir)
    ruby_files = Dir.glob(dir + '*.rb')
    ruby_files.each do |rf|
      require rf unless rf =~/workflow/
    end
  end

  # set ISAAC_PATH=<path to isaac workspace>
  local_isaac = ENV['ISAAC_PATH']
  local_isaac_rest = ENV['ISAAC_PATH'].to_s + '/ISAAC-rest'

  desc 'Build local isaac rest project'
  task :build_isaac_rest do |task|
    if local_isaac
      sh "cd #{local_isaac_rest} && git pull"
      sh "cd #{local_isaac_rest} && mvn clean install"
      Rake::Task['isaac:generate_metadata_auxiliary'].invoke
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

  desc 'This task generates IsaacMetadataAuxiliary.yaml'
  task :generate_metadata_auxiliary do
    sh 'mvn -U initialize'
  end

  desc 'This task launches isaac rest'
  task :launch_isaac_rest do
    sh "cd #{local_isaac_rest}/ && mvn compile -Pstart-server"
  end

  desc 'This task builds isaac rest, generates the metadata file and launches isaac rest'
  task :build_and_launch_isaac_rest do
    Rake::Task['isaac:build_isaac_rest'].invoke
    Rake::Task['isaac:launch_isaac_rest'].invoke
  end

  desc 'Build local isaac rest project'
  task :build_r => :build_isaac_rest
  desc 'Build local isaac rest project'
  task :br => :build_isaac_rest

  desc 'Build local isaac rest project'
  task :b => :build_all

  desc 'This task builds isaac rest, generates the metadata file and launches isaac rest'
  task :bal => :build_and_launch_isaac_rest

end
