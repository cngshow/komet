require 'logging'
#turn off warnings
v = $VERBOSE
$VERBOSE = nil
module Logging
  #opening and redefining LogEvent found in log_event.rb
  # This class defines a logging event.
  #
  LogEvent = Struct.new( :logger, :level, :data, :time, :file, :line, :method ) {
    # :stopdoc:

    # Regular expression used to parse out caller information
    #
    # * $1 == filename
    # * $2 == line number
    # * $3 == method name (might be nil)
    CALLER_RGXP = %r/([-\.\/\(\)\w]+):(\d+)(?::in `(\w+)')?/o
    #CALLER_INDEX = 2
    CALLER_INDEX = ((defined? JRUBY_VERSION and JRUBY_VERSION > '1.6') or (defined? RUBY_ENGINE and RUBY_ENGINE[%r/^rbx/i])) ? 1 : 2
    # :startdoc:

    # call-seq:
    #    LogEvent.new( logger, level, [data], caller_tracing )
    #
    # Creates a new log event with the given _logger_ name, numeric _level_,
    # array of _data_ from the user to be logged, and boolean _caller_tracing_ flag.
    # If the _caller_tracing_ flag is set to +true+ then Kernel::caller will be
    # invoked to get the execution trace of the logging method.
    #
    def initialize( logger, level, data, caller_tracing )
      f = l = m = ''

      if caller_tracing
        stack = Kernel.caller[CALLER_INDEX]
        return if stack.nil?

        match = CALLER_RGXP.match(stack)
        f = match[1]
        separator = java.io.File.separator
        rr = Rails.root.to_s.split(separator)
        rr.shift if separator.eql?("\\")#windows get rid of drive letter
        f.gsub!('/' + rr.join('/'),'')
        l = Integer(match[2])
        m = match[3] unless match[3].nil?
      end

      super(logger, level, data, Time.now, f, l, m)
    end
  }

end  # module Logging
#put warnings back to whatever they are.
$VERBOSE = v
# here we setup a color scheme called 'bright'

#Logging.caller_tracing=true
Logging.init :debug, :info, :warn, :error, :fatal, :always

Logging.color_scheme('pretty',
                     levels: {
                         :info => :green,
                         :warn => :yellow,
                         :error => :red,
                         :fatal => [:white, :on_red],
                         :always => :white
                     },
                     date: :yellow,
                     #logger: :cyan,
                     #message: :magenta,
                     file: :magenta,
                     line: :cyan
)
#move pattern to prop file
pattern = $PROPS['LOG.pattern']
Logging.appenders.stdout(
    'stdout',
    :layout => Logging.layouts.pattern(
        :pattern => pattern,
        :color_scheme => 'pretty'
    )
)

rf = Logging.appenders.rolling_file(
    'file',
    layout: Logging.layouts.pattern(
        pattern: pattern,
        color_scheme: 'pretty',
    #    backtrace: true
    ),
    roll_by: $PROPS['LOG.roll_by'],
    keep: $PROPS['LOG.keep'].to_i,
    age: $PROPS['LOG.age'],
    filename: $PROPS['LOG.filename'],
    truncate: true
)

begin

  $log = ::Logging::Logger['MainLogger']
  $log.caller_tracing=$PROPS['LOG.caller_tracing'].upcase.eql?('TRUE')

  $log.add_appenders 'stdout' unless $PROPS['LOG.append_stdout'].nil?
  $log.add_appenders rf
  $log.level = $PROPS['LOG.level'].downcase.to_sym

# these log messages will be nicely colored
# the level will be colored differently for each message
#
  unless ( File.basename($0) == 'rake')
    $log.always "Logging started!"
  end
rescue => ex
  warn "Logger failed to initialize.  Reason is " + ex.to_s
  warn ex.backtrace.join("\n")
  warn "Shutting down the ETS web server!"
  java.lang.System.exit(1)
end
