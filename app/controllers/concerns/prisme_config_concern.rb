module PrismeConfig

  def self.config
    return @@config unless @@config.nil?
    config_url = URI $PROPS['PRISME.prisme_config_url']
    conn = get_rest_connection(config_url.base_url)
    error = false
    begin
      user_params  = {}
      user_params[:format] = 'json'
      config_body = conn.get(roles_url.path, user_params).body
      $log.debug("Roles body from prisme is: #{config_body}")
      @@config = JSON.parse config_body
    rescue => ex
      $log.error("Komet could not communicate with PRISME at URL #{config_url}")
      $log.error("Error message is #{ex.message}")
    end
    @@config
  end

  def self.logout_link
    PrismeUtilities.ssoi_logout_path_from_json_string(config)
  end

end