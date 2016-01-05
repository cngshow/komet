class EtsDashboardController < ApplicationController

  before_action :setup_routes, :only => [:dashboard]

  def setup_routes
    routes = Rails.application.routes.named_routes.helpers.to_a
    routes_hash = {}
    routes.each do |route|
      routes_hash[route.to_s] = self.send(route)
    end
    $log.debug("routes hash passed to javascript is " + routes_hash.to_s)
    gon.routes = routes_hash
  end

  def dashboard
  end
end
