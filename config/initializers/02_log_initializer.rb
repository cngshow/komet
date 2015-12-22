require 'logging'

# here we setup a color scheme called 'bright'

#Logging.caller_tracing=true

Logging.color_scheme('pretty',
                     levels: {
                         :info => :green,
                         :warn => :yellow,
                         :error => :red,
                         :fatal => [:white, :on_red]
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
#Logging.logger.caller_tracing=true
#$log = Logging.logger["main"]
begin
  $log = ::Logging::Logger['MainLogger']
  $log.caller_tracing=$PROPS['LOG.caller_tracing'].upcase.eql?('TRUE')

  $log.add_appenders 'stdout' unless $PROPS['LOG.append_stdout'].nil?
  $log.add_appenders rf
  $log.level = $PROPS['LOG.level'].downcase.to_sym

# these log messages will be nicely colored
# the level will be colored differently for each message
#
  $log.info "Logging started."
rescue => ex
  warn "Logger failed to initialize.  Reason is " + ex.to_s
  warn ex.backtrace.join("\n")
  warn "Shutting down the ETS web server!"
  java.lang.System.exit(1)
end
