# Be sure to restart your server when you modify this file.
context_file = "../context.txt"
key = File.open(context_file).read.reverse.chop.reverse rescue "_komet_tooling_session"
key += '_' + File.mtime(context_file).to_i.to_s rescue ''
Rails.application.config.session_store :cache_store, key: key
$log.always("Session store key is #{key}")