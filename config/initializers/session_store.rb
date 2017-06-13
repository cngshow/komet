# Be sure to restart your server when you modify this file.
return if $react_build

context_file = "../context.txt"
key = File.open(context_file).read.reverse.chop.reverse rescue "_komet_tooling_session"
context = (key.eql? '_komet_tooling_session') ? '' : key
message = "#{Rails.application.class.parent_name}/#{context} coming up!"
message << "  The version is #{$PROPS['PRISME.war_version']}" if $PROPS['PRISME.war_version']
$log.always_n(PrismeLogEvent::LIFECYCLE_TAG, message) unless $rake
$CONTEXT = (context.empty?) ? '/' : context
key += '_' + File.mtime(context_file).to_i.to_s rescue ''
Rails.application.config.session_store :cache_store, key: key
$log.always("Session store key is #{key}") unless $rake