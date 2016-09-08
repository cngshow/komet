module PrismeConfigConcern
  class << self
    attr_accessor :config
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

  def self.logout_link
    PrismeUtilities.ssoi_logout_path_from_json_string(config_hash: get_config)
  end

end