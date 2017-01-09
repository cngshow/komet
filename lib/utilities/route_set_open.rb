module ActionDispatch
  module Http
    module URL
      class << self
        def path_for(options)
          path  = options[:script_name].to_s.chomp("/")
          path << options[:path] if options.key?(:path)
          add_trailing_slash(path) if options[:trailing_slash]
          add_params(path, options[:params]) if options.key?(:params)
          add_anchor(path, options[:anchor]) if options.key?(:anchor)
          proxy_helper = Thread.current.thread_variable_get(:proxy_helper_lambda)
          proxy_helper.nil? ? path : proxy_helper.call(path)
        end
      end
    end
  end
end

