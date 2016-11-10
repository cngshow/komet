module PrismeConfigConcern
  class << self
    attr_accessor :config
    attr_accessor :isaac_proxy_context
  end

  def self.get_config
    return PrismeConfigConcern.config unless PrismeConfigConcern.config.nil?
    raise 'KOMET is not configured properly.' if $PROPS['PRISME.prisme_config_url'].nil?
    config_url = URI $PROPS['PRISME.prisme_config_url']
    conn = CommonController.get_rest_connection(config_url.base_url)
    begin
      user_params  = {}
      user_params[:format] = 'json'
      config_body = conn.get(config_url.path, user_params).body
      $log.debug("Config body from prisme is: #{config_body}")
      PrismeConfigConcern.config = JSON.parse config_body
    rescue => ex
      $log.error("KOMET could not communicate with PRISME at URL #{config_url}")
      $log.error("Error message is #{ex.message}")
    end
    PrismeConfigConcern.config
  end

  def self.get_isaac_proxy_context
    return PrismeConfigConcern.isaac_proxy_context unless PrismeConfigConcern.isaac_proxy_context.nil?
    get_config
    begin
      PrismeConfigConcern.config['proxy_config_root']['proxy_urls'].each do |e|
        if (((URI e['incoming_url_path']).eql_ignore_trailing_slash? ISAAC_ROOT))
          PrismeConfigConcern.isaac_proxy_context= e['proxy_location']
          break
        end
      end
    rescue => ex
      $log.error("I could not parse the isaac proxy data. #{ex}")
    end
    if PrismeConfigConcern.isaac_proxy_context.nil?
      context = (URI ISAAC_ROOT).path
      $log.error("For isaac root #{ISAAC_ROOT} my prisme instance has no proxy config entry!  I have no idea what the context is for isaac rest on the other side of the proxy!!")
      $log.error("I am going to assume a context of #{context}.  If the vhat export is pulling from the wrong isaac instance this is why...")
      return context
    end
    PrismeConfigConcern.isaac_proxy_context
  end

  def self.logout_link
    PrismeUtilities.ssoi_logout_path_from_json_string(config_hash: get_config)
  end

end
=begin
load('./app/controllers/concerns/prisme_config_concern.rb')
PrismeConfigConcern.get_isaac_proxy_context
=end
