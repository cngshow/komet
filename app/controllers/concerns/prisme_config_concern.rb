require 'fileutils'
module PrismeConfigConcern
  class << self
    attr_accessor :config
    attr_accessor :isaac_proxy_context
    attr_accessor :proxy_css
  end

  PROXY_CSS_DIR = '../assets/'
  PROXY_CSS_BASE_PREPEND = 'proxy_'

  def self.proxy_css_file_exists?
    !get_proxy_css_file.nil?
  end

  def self.get_proxy_css_file
    Dir.glob(PROXY_CSS_DIR + PROXY_CSS_BASE_PREPEND + 'application*.css').first
  end

  def self.create_proxy_css(proxy_string:, context:)
    return if PrismeConfigConcern.proxy_css
    PrismeConfigConcern.proxy_css = true if proxy_css_file_exists?
    unless PrismeConfigConcern.proxy_css
      begin
        css_file =  Dir.glob(PROXY_CSS_DIR + 'application*.css').first
        if css_file
          css_string = File.open(css_file, "rb").read
          css_string.gsub!("#{context}", proxy_string)
          proxy_file_name = PROXY_CSS_BASE_PREPEND + File.basename(css_file)
          File.open(PROXY_CSS_DIR + proxy_file_name, 'wb') { |file| file.write(css_string) }
          PrismeConfigConcern.proxy_css = true
        end
      rescue => ex
        $log.error("Failed to write css proxy file! #{ex}")
        $log.error(ex.backtrace.join("\n"))
      end
    end
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

  #http://localhost:8090/rails_komet_a/komet_dashboard/dashboard (sample url_string)
  def self.recontext(url_string: , controller:)
    host = controller.true_address
    port = controller.true_port
    context = $CONTEXT
    context = '/' + context unless context[0].eql? '/'
    proxy_location = get_proxy_location(host: host, port: port)
    $log.info("proxy location is #{proxy_location}")
    path_proxified = (URI url_string).path.gsub(context, proxy_location).gsub('//','/') #final gsub is in case proxy_location ends in /
    $log.info("path_proxified is #{path_proxified}, context is #{context}")
    path_proxified = '/' + path_proxified unless path_proxified[0].eql? '/'
    $log.info("path_proxified is now #{path_proxified}, context is #{context}")
    uri = URI url_string
    uri.path = path_proxified
    $log.info ("path is #{uri}")
    uri.to_s
  end


  def self.get_proxy_location(host:, port:)
    PrismeConfigConcern.proxy_urls.each do |k|
      uri = URI k['incoming_url_path']
      port = uri.port
      $log.info(uri.host + " : " + port.to_s)
      return k['proxy_location'] if (host.eql?(uri.host) && port.to_s.eql?(port.to_s))
    end
    $log.warn("I could not find a valid proxy config for host #{host} with port #{port}.  Check prisme's server_config.yml")
    $CONTEXT
  end

  def self.application_urls
    get_config['application_urls']
  end

  def self.get_proxy
    get_config['proxy_config_root']['apache_url_proxy']
  end

  def self.proxy_urls
    get_config['proxy_config_root']['proxy_urls']
  end

  def self.logout_link
    PrismeUtilities.ssoi_logout_path_from_json_string(config_hash: get_config)
  end

end
=begin
load('./app/controllers/concerns/prisme_config_concern.rb')
PrismeConfigConcern.get_isaac_proxy_context
=end
