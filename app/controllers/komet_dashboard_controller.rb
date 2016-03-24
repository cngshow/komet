class KometDashboardController < ApplicationController

  before_action :setup_routes, :setup_constants, :only => [:dashboard]
  include ISAACConstants

  def setup_routes
    routes = Rails.application.routes.named_routes.helpers.to_a
    routes_hash = {}
    routes.each do |route|
      begin
        routes_hash[route.to_s] = self.send(route)
      rescue ActionController::UrlGenerationError => ex
        if (ex.message =~ /missing required keys: \[(.*?)\]/)
          keys = $1
          keys = keys.split(',')
          keys.map! do |e|
            e.gsub!(':','')
            e.strip
          end
          required_keys_hash = {}
          keys.each do |key|
            required_keys_hash[key.to_sym] = ':' + key.to_s
          end
          routes_hash[route.to_s] = self.send(route, required_keys_hash)
        else
          raise ex
        end
      end
    end

    $log.debug('routes hash passed to javascript is ' + routes_hash.to_s)
    gon.routes = routes_hash
  end

  def setup_constants
    initialize_isaac_constants
    $log.debug('term_aux hash passed to javascript is ' + ISAACConstants::TERMAUX.to_s)
    gon.term_aux = ISAACConstants::TERMAUX
  end

  def dashboard
  end

  def metadata
  end

end
