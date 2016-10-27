namespace :isaac do

  def require_all(dir)
    ruby_files = Dir.glob(dir + '*.rb')
    ruby_files.each do |rf|
      require rf
    end
  end

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

  desc 'This task hits the isaac rest server. Builds all Isaac metadata + translations. Maven (mvn) must be on your path'
  task :metadata_auxiliary => :environment do
    raise "Issac root is not defined.  You can set the environment variable ISAAC_ROOT=http://my.isaac.instance.com" if ISAAC_ROOT.empty?
    system('mvn -U initialize')
    puts("Starting rest calls, a tails of the log will let you observer the progress...")
    require_all './lib/isaac_rest/'
    ApplicationController.parse_isaac_metadata_auxiliary
    dump = Marshal.dump($isaac_metadata_auxiliary)
    open(ApplicationController::METADATA_DUMP_FILE, 'wb') { |f| f.puts dump }
    puts("Done!")
  end


  desc 'Build local isaac rest project'
  task :build_r => :build_isaac_rest
  desc 'Build local isaac rest project'
  task :br => :build_isaac_rest

  desc 'Build local isaac rest project'
  task :b => :build_all

end
