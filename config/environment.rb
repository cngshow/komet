# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Rails.application.initialize!
require 'active_resource'
ActiveResource::Base.logger = $log